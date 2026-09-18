import Combine

@MainActor
final class HarmonicaViewModel: ObservableObject {
    @Published private(set) var state: HarmonicaViewState = .preparingSound

    private let playHarmonica: PlayHarmonica
    private let playScore: PlayScore
    private let tilt: TiltProtocol
    private let tunes: [Score]
    private let presenter: HarmonicaPresenter
    private var performance: Task<Void, Never>?

    // MARK: - Public

    init(
        playHarmonica: PlayHarmonica,
        playScore: PlayScore,
        tilt: TiltProtocol,
        tunes: [Score],
        presenter: HarmonicaPresenter
    ) {
        self.playHarmonica = playHarmonica
        self.playScore = playScore
        self.tilt = tilt
        self.tunes = tunes
        self.presenter = presenter
    }

    func prepareSound() async {
        do {
            let harmonica = try await playHarmonica.prepare()
            show(harmonica)
        } catch {
            publish(presenter.presentSoundUnavailable())
        }
    }

    func play(at positions: [PositionOnHarmonica]) {
        guard case .ready = state else { return }

        if !positions.isEmpty {
            stopTheScore()
        }
        show(playHarmonica.play(at: positions))
    }

    func followTheTilt() async {
        for await leaning in tilt.tiltToTheRight() {
            cupHands(to: CupDepth(clamping: leaning))
        }
    }

    func changeKey(toPosition position: Double) {
        guard case .ready = state else { return }

        let key = HarmonicaKey(nearestSliderPosition: Int(position.rounded()))
        show(playHarmonica.changeKey(to: key))
    }

    func changeStyle(to choice: PlayingStyleChoice) {
        guard case .ready = state else { return }

        show(playHarmonica.changeStyle(to: Self.style(chosen: choice)))
    }

    func playTheTune(at index: Int) {
        guard case .ready = state, tunes.indices.contains(index) else { return }

        stopTheScore()
        let tune = tunes[index]
        performance = Task { [weak self] in
            await self?.perform(tune)
        }
    }

    func stopTheTune() {
        guard case .ready = state else { return }

        stopTheScore()
        show(playHarmonica.stopPlaying(.ringsDown))
    }

    func shapeTone(pitch: Double, vibrato: Double) {
        let harmonica = playHarmonica.shapeTone(
            PitchShaping(clamping: pitch),
            vibrato: VibratoDepth(clamping: vibrato)
        )
        guard case .ready = state else { return }

        show(harmonica)
    }

    func stopShapingTone() {
        shapeTone(pitch: 0, vibrato: 0)
    }

    func stopPlaying() {
        stopTheScore()
        let harmonica = playHarmonica.stopPlaying(.ringsDown)
        guard case .ready = state else { return }

        show(harmonica)
    }

    // MARK: - Private

    private func perform(_ tune: Score) async {
        for await harmonica in playScore.play(tune) {
            show(harmonica)
        }
        performance = nil
        show(playHarmonica.stopPlaying(.ringsDown))
    }

    private func cupHands(to cup: CupDepth) {
        let harmonica = playHarmonica.cupHands(to: cup)
        guard case .ready = state else { return }

        show(harmonica)
    }

    private static func style(chosen choice: PlayingStyleChoice) -> PlayingStyle {
        switch choice {
        case .severalFingersSeveralNotes: .severalFingersSeveralNotes
        case .severalFingersOneNote: .severalFingersOneNote
        case .oneFingerSeveralNotes: .oneFingerSeveralNotes
        }
    }

    private func stopTheScore() {
        performance?.cancel()
        performance = nil
    }

    private func show(_ harmonica: Harmonica) {
        publish(presenter.present(harmonica, playingAScore: performance != nil))
    }

    private func publish(_ updated: HarmonicaViewState) {
        guard updated != state else { return }

        state = updated
    }
}
