import Combine
import HarmonicaCore

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var state: SettingsViewState

    private let repository: SettingsRepository
    private let presenter: SettingsPresenter
    private let log: LogProtocol
    private var settings: PlayerSettings

    // MARK: - Public

    init(repository: SettingsRepository, presenter: SettingsPresenter, log: LogProtocol) {
        self.repository = repository
        self.presenter = presenter
        self.log = log
        let stored = repository.settings()
        settings = stored
        state = presenter.present(stored)
    }

    func chooseStyle(_ choice: SettingsViewState.StyleChoice) {
        let style = Self.style(chosen: choice)
        guard style != settings.style else { return }

        settings.style = style
        log.record("playing style chosen in the settings: \(style)")
        save()
    }

    func turnCupping(on isOn: Bool) {
        guard isOn != settings.isCuppingEnabled else { return }

        settings.isCuppingEnabled = isOn
        log.record("cupping turned \(isOn ? "on" : "off") in the settings")
        save()
    }

    func placeSquare(_ placement: SquarePlacement) {
        guard placement != settings.squarePlacement else { return }

        settings.squarePlacement = placement
        log.record("square placed on the \(placement) in the settings")
        save()
    }

    func resizeSquare(to fraction: Double) {
        let size = SquareSize(clamping: fraction)
        guard size != settings.squareSize else { return }

        settings.squareSize = size
        log.recordSample("square resized to \(size.fraction) of its range in the settings")
        save()
    }

    // MARK: - Private

    private static func style(chosen choice: SettingsViewState.StyleChoice) -> PlayingStyle {
        switch choice {
        case .severalFingersSeveralNotes: .severalFingersSeveralNotes
        case .severalFingersOneNote: .severalFingersOneNote
        case .oneFingerSeveralNotes: .oneFingerSeveralNotes
        }
    }

    private func save() {
        repository.save(settings)
        state = presenter.present(settings)
    }
}
