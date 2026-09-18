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
            let harmonica = try await playHarmonica.prepare()
            show(presenter.present(harmonica))
        } catch {
            show(presenter.presentSoundUnavailable())
        }
    }

    func play(at positions: [PositionOnHarmonica]) {
        guard case .ready = state else { return }

        show(presenter.present(playHarmonica.play(at: positions)))
    }

    func changeKey(toPosition position: Double) {
        guard case .ready = state else { return }

        let key = HarmonicaKey(nearestPosition: Int(position.rounded()))
        show(presenter.present(playHarmonica.changeKey(to: key)))
    }

    func changeStyle(toMouth isMouth: Bool) {
        guard case .ready = state else { return }

        show(presenter.present(playHarmonica.changeStyle(to: isMouth ? .mouth : .fingers)))
    }

    func changeOverbendStyle(toSnap isSnap: Bool) {
        guard case .ready = state else { return }

        show(presenter.present(playHarmonica.changeOverbendStyle(to: isSnap ? .snap : .smooth)))
    }

    func shapeTone(bend: Double, vibrato: Double) {
        let harmonica = playHarmonica.shapeTone(
            bend: BendDepth(clamping: bend),
            vibrato: VibratoDepth(clamping: vibrato)
        )
        guard case .ready = state else { return }

        show(presenter.present(harmonica))
    }

    func stopShapingTone() {
        shapeTone(bend: 0, vibrato: 0)
    }

    func stopPlaying() {
        let harmonica = playHarmonica.stopPlaying()
        guard case .ready = state else { return }

        show(presenter.present(harmonica))
    }

    // MARK: - Private

    private func show(_ updated: HarmonicaViewState) {
        guard updated != state else { return }

        state = updated
    }
}
