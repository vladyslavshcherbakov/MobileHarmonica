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
            show(presenter.present(soundingHoles: [], key: playHarmonica.key))
        } catch {
            show(presenter.presentSoundUnavailable())
        }
    }

    func play(at positions: [PositionOnHarmonica]) {
        guard case .ready = state else { return }

        show(presenter.present(soundingHoles: playHarmonica.play(at: positions), key: playHarmonica.key))
    }

    func changeKey(toPosition position: Double) {
        guard case .ready = state else { return }

        let key = HarmonicaKey(nearestPosition: Int(position.rounded()))
        show(presenter.present(soundingHoles: playHarmonica.changeKey(to: key), key: key))
    }

    func stopPlaying() {
        playHarmonica.stopPlaying()
        guard case .ready = state else { return }

        show(presenter.present(soundingHoles: [], key: playHarmonica.key))
    }

    // MARK: - Private

    private func show(_ updated: HarmonicaViewState) {
        guard updated != state else { return }

        state = updated
    }
}
