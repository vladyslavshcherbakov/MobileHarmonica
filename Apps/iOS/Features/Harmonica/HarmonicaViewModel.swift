import Combine

final class HarmonicaViewModel: ObservableObject {
    @Published private(set) var state: HarmonicaViewState = .preparingSound

    private let playHarmonica: PlayHarmonica
    private let presenter: HarmonicaPresenter

    // MARK: - Public

    init(playHarmonica: PlayHarmonica, presenter: HarmonicaPresenter) {
        self.playHarmonica = playHarmonica
        self.presenter = presenter
    }

    @MainActor
    func prepareSound() async {
        do {
            try await playHarmonica.prepare()
            show(presented(soundingHoles: []))
        } catch {
            show(presenter.presentSoundUnavailable())
        }
    }

    func play(at positions: [PositionOnHarmonica]) {
        guard case .ready = state else { return }

        show(presented(soundingHoles: playHarmonica.play(at: positions)))
    }

    func changeKey(toPosition position: Double) {
        guard case .ready = state else { return }

        let key = HarmonicaKey(nearestPosition: Int(position.rounded()))
        show(presented(soundingHoles: playHarmonica.changeKey(to: key)))
    }

    func shapeTone(bend: Double, vibrato: Double) {
        playHarmonica.shapeTone(bend: BendDepth(clamping: bend), vibrato: VibratoDepth(clamping: vibrato))
    }

    func stopShapingTone() {
        playHarmonica.shapeTone(bend: .unbent, vibrato: .off)
    }

    func stopPlaying() {
        playHarmonica.stopPlaying()
        guard case .ready = state else { return }

        show(presented(soundingHoles: []))
    }

    // MARK: - Private

    private func presented(soundingHoles: Set<Hole>) -> HarmonicaViewState {
        presenter.present(
            soundingHoles: soundingHoles,
            key: playHarmonica.key,
            bendableSemitones: playHarmonica.bendableSemitones
        )
    }

    private func show(_ updated: HarmonicaViewState) {
        guard updated != state else { return }

        state = updated
    }
}
