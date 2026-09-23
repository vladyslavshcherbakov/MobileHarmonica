import Combine
import CoreGraphics
import HarmonicaCore

@MainActor
final class HarmonicaViewModel: ObservableObject {
    @Published private(set) var state: HarmonicaViewState = .preparingSound

    private let playHarmonica: PlayHarmonicaUseCase
    private let playScore: PlayScoreUseCase
    private let tilt: TiltProtocol
    private let settingsRepository: SettingsRepository
    private let tunes: [Score]
    private let presenter: HarmonicaPresenter
    private let log: LogProtocol
    private var settings: PlayerSettings
    private var performance: Task<Void, Never>?

    // MARK: - Public

    init(
        playHarmonica: PlayHarmonicaUseCase,
        playScore: PlayScoreUseCase,
        tilt: TiltProtocol,
        settingsRepository: SettingsRepository,
        tunes: [Score],
        presenter: HarmonicaPresenter,
        log: LogProtocol
    ) {
        self.playHarmonica = playHarmonica
        self.playScore = playScore
        self.tilt = tilt
        self.settingsRepository = settingsRepository
        self.tunes = tunes
        self.presenter = presenter
        self.log = log
        settings = settingsRepository.settings()
    }

    deinit {
        performance?.cancel()
    }

    func prepareSound() async {
        do throws(AudioEngineError) {
            _ = try await playHarmonica.prepare()
            show(adoptTheStoredSettings())
        } catch {
            publish(presenter.presentSoundUnavailable(because: error))
        }
    }

    func applyTheSettings() {
        guard isReady(toTake: "the settings") else { return }

        show(adoptTheStoredSettings())
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

    func followTheTilt() async {
        guard settings.isCuppingEnabled else {
            log.record("cupping is off in the settings, the lean of the phone is not followed")
            return
        }

        for await leaning in tilt.tiltToTheRight() {
            cupHands(to: CupDepth(clamping: leaning))
        }
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

    func resizeSquare(by magnification: CGFloat, within area: CGSize) {
        guard isReady(toTake: "a pinch on the square") else { return }

        let size = SquareSizing(in: area).size(afterPinching: settings.squareSize, by: magnification)
        guard size != settings.squareSize else { return }

        settings.squareSize = size
        settingsRepository.save(settings)
        log.recordSample("square resized to \(size.fraction) of its range")
        show(playHarmonica.harmonica)
    }

    func stopShapingTone() {
        shapeTone(.rest, vibrato: .off)
    }

    func stopPlaying() {
        guard isReady(toTake: "stopping the sound") else { return }

        stopTheScore()
        show(playHarmonica.stopPlaying(.ringsDown))
    }

    // MARK: - Private

    private func adoptTheStoredSettings() -> Harmonica {
        settings = settingsRepository.settings()
        let styled = playHarmonica.changeStyle(to: settings.style)
        guard !settings.isCuppingEnabled else { return styled }

        return playHarmonica.cupHands(to: .open)
    }

    private func perform(_ tune: Score) -> Task<Void, Never> {
        Task { [weak self, playScore] in
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

    private func cupHands(to cup: CupDepth) {
        guard isReady(toTake: "a lean of the phone") else { return }

        show(playHarmonica.cupHands(to: cup))
    }

    private func isReady(toTake action: String) -> Bool {
        guard case .ready = state else {
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
        publish(presenter.present(harmonica, settings: settings, playingAScore: performance != nil))
    }

    private func publish(_ updated: HarmonicaViewState) {
        guard updated != state else { return }

        state = updated
    }
}
