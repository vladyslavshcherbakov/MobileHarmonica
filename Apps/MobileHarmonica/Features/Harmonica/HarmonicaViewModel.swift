import Combine

final class HarmonicaViewModel: ObservableObject {
    @Published private(set) var state: HarmonicaViewState = .preparingSound

    private let blowIntoHarmonica: BlowIntoHarmonica
    private let presenter: HarmonicaPresenter

    // MARK: - Public

    init(blowIntoHarmonica: BlowIntoHarmonica, presenter: HarmonicaPresenter) {
        self.blowIntoHarmonica = blowIntoHarmonica
        self.presenter = presenter
    }

    func prepareSound() {
        do {
            try blowIntoHarmonica.prepare()
            show(presenter.present(soundingHole: nil))
        } catch {
            show(presenter.presentSoundUnavailable())
        }
    }

    func blow(at position: PositionAlongHarmonica) {
        guard case .ready = state else { return }

        show(presenter.present(soundingHole: blowIntoHarmonica.blow(at: position)))
    }

    func stopBlowing() {
        blowIntoHarmonica.stopBlowing()
        guard case .ready = state else { return }

        show(presenter.present(soundingHole: nil))
    }

    // MARK: - Private

    private func show(_ updated: HarmonicaViewState) {
        guard updated != state else { return }

        state = updated
    }
}
