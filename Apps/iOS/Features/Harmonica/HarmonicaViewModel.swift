import Combine

final class HarmonicaViewModel: ObservableObject {
    @Published private(set) var state: HarmonicaViewState = .preparingSound

    private let playHarmonica: PlayHarmonica
    private let playScore: PlayScore
    private let demo: Score
    private let presenter: HarmonicaPresenter
    private var performance: Task<Void, Never>?

    // MARK: - Public

    init(playHarmonica: PlayHarmonica, playScore: PlayScore, demo: Score, presenter: HarmonicaPresenter) {
        self.playHarmonica = playHarmonica
        self.playScore = playScore
        self.demo = demo
        self.presenter = presenter
    }

    @MainActor
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

    func changeKey(toPosition position: Double) {
        guard case .ready = state else { return }

        let key = HarmonicaKey(nearestSliderPosition: Int(position.rounded()))
        show(playHarmonica.changeKey(to: key))
    }

    func changeStyle(toMouth isMouth: Bool) {
        guard case .ready = state else { return }

        show(playHarmonica.changeStyle(to: isMouth ? .mouth : .fingers))
    }

    func playTheDemo() {
        guard case .ready = state else { return }
        guard performance == nil else {
            stopTheScore()
            show(playHarmonica.stopPlaying())
            return
        }

        performance = Task { @MainActor [weak self] in
            await self?.perform()
        }
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
        let harmonica = playHarmonica.stopPlaying()
        guard case .ready = state else { return }

        show(harmonica)
    }

    // MARK: - Private

    @MainActor
    private func perform() async {
        for await harmonica in playScore.play(demo) {
            show(harmonica)
        }
        performance = nil
        show(playHarmonica.stopPlaying())
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
