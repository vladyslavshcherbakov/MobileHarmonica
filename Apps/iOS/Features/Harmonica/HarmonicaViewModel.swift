import Combine
import CoreGraphics
import HarmonicaCore

@MainActor
final class HarmonicaViewModel: ObservableObject {
    @Published private(set) var state: HarmonicaViewState?

    private let playHarmonica: PlayHarmonicaUseCase
    private let playScore: PlayScoreUseCase
    private let tunes: [Score]
    private let presenter: HarmonicaPresenter
    private let log: LogProtocol
    private var performance: Task<Void, Never>?

    // MARK: - Public

    init(
        playHarmonica: PlayHarmonicaUseCase,
        playScore: PlayScoreUseCase,
        tunes: [Score],
        presenter: HarmonicaPresenter,
        log: LogProtocol
    ) {
        self.playHarmonica = playHarmonica
        self.playScore = playScore
        self.tunes = tunes
        self.presenter = presenter
        self.log = log
    }

    deinit {
        performance?.cancel()
    }

    func prepare(adopting settings: PlayerSettings) async throws(AudioEngineError) {
        do throws(AudioEngineError) {
            _ = try await playHarmonica.prepare()
        } catch {
            state = nil
            throw error
        }
        show(harmonica(adopting: settings))
    }

    func adopt(_ settings: PlayerSettings) {
        guard isReady(toTake: "the settings") else { return }

        show(harmonica(adopting: settings))
    }

    func play(_ touches: [FingerTouch], across size: CGSize) {
        guard isReady(toTake: "a touch on the strip") else { return }

        if !touches.isEmpty {
            stopTheScore()
        }
        show(playHarmonica.play(at: StripTouchMapper(touches, across: size).positions))
    }

    func marksOnTheStrip(
        for touches: [FingerTouch],
        across size: CGSize,
        style: HarmonicaViewState.FingerMarks
    ) -> [FingerMark] {
        StripTouchMapper(touches, across: size).marks(drawn: style)
    }

    func marksOnTheSquare(for touches: [FingerTouch], across size: CGSize) -> [FingerMark] {
        SquareTouchMapper(touches, across: size).marks
    }

    func cupHands(toLeaning leaning: Double) {
        guard isReady(toTake: "a lean of the phone") else { return }

        show(playHarmonica.cupHands(to: CupDepth(clamping: leaning)))
    }

    func changeKey(toPosition position: Double) {
        guard isReady(toTake: "a key change") else { return }

        let key = HarmonicaKey(nearestSliderPosition: Int(position.rounded()))
        show(playHarmonica.changeKey(to: key))
    }

    func playTheTune(at index: Int) {
        guard isReady(toTake: "a tune") else { return }
        guard tunes.indices.contains(index) else {
            assertionFailure("the menu offered tune \(index) of \(tunes.count)")
            log.record("tune \(index) was asked for, there are \(tunes.count), nothing plays")
            return
        }

        stopTheScore()
        performance = perform(tunes[index])
    }

    func stopTheTune() {
        guard isReady(toTake: "stopping the tune") else { return }

        stopTheScore()
        show(playHarmonica.stopPlaying(.ringsDown))
    }

    func shapeTone(with touches: [FingerTouch], across size: CGSize) {
        let square = SquareTouchMapper(touches, across: size)
        guard let shaping = square.pitchShaping, let vibrato = square.vibrato else {
            stopShapingTone()
            return
        }

        shapeTone(shaping, vibrato: vibrato)
    }

    func stopShapingTone() {
        shapeTone(.rest, vibrato: .off)
    }

    func silence() {
        guard isReady(toTake: "silencing the harmonica") else { return }

        stopTheScore()
        show(playHarmonica.stopPlaying(.ringsDown))
        stopShapingTone()
    }

    // MARK: - Private

    private func harmonica(adopting settings: PlayerSettings) -> Harmonica {
        let styled = playHarmonica.changeStyle(to: settings.style)
        guard !settings.isCuppingEnabled else { return styled }

        log.record("cupping is off in the settings, the hands stay open")
        return playHarmonica.cupHands(to: .open)
    }

    private func perform(_ tune: Score) -> Task<Void, Never> {
        Task { [weak self, playScore] in
            guard !Task.isCancelled else { return }

            for await harmonica in playScore.play(tune) {
                guard let self else { return }

                self.show(harmonica)
            }
            guard !Task.isCancelled else { return }

            self?.finishTheTune()
        }
    }

    private func finishTheTune() {
        performance = nil
        show(playHarmonica.stopPlaying(.ringsDown))
    }

    private func shapeTone(_ shaping: PitchShaping, vibrato: VibratoDepth) {
        guard isReady(toTake: "a touch on the square") else { return }

        show(playHarmonica.shapeTone(shaping, vibrato: vibrato))
    }

    private func isReady(toTake action: String) -> Bool {
        guard state != nil else {
            log.recordSample("\(action) arrived while the sound was not ready, nothing changed")
            return false
        }

        return true
    }

    private func stopTheScore() {
        performance?.cancel()
        performance = nil
    }

    private func show(_ harmonica: Harmonica) {
        let updated = presenter.present(harmonica, playingAScore: performance != nil)
        guard updated != state else { return }

        state = updated
    }
}
