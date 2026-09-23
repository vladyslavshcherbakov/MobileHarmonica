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
        let storedSettings = repository.settings()
        settings = storedSettings
        state = presenter.present(storedSettings)
    }

    func send(_ action: SettingsAction) {
        switch action {
        case .styleChosen(let choice):
            chooseStyle(choice)
        case .cuppingTurned(on: let isOn):
            turnCupping(on: isOn)
        case .shapingPadPlaced(let placement):
            placeShapingPad(placement)
        case .shapingPadSizeSliderMoved(to: let fraction):
            resizeShapingPad(to: fraction)
        }
    }

    // MARK: - Private

    private static func style(chosen choice: SettingsViewState.StyleChoice) -> PlayingStyle {
        switch choice {
        case .severalFingersSeveralNotes: .severalFingersSeveralNotes
        case .severalFingersOneNote: .severalFingersOneNote
        case .oneFingerSeveralNotes: .oneFingerSeveralNotes
        }
    }

    private func chooseStyle(_ choice: SettingsViewState.StyleChoice) {
        let style = Self.style(chosen: choice)
        guard style != settings.style else { return }

        settings.style = style
        log.record("playing style chosen in the settings: \(style)")
        save()
    }

    private func turnCupping(on isOn: Bool) {
        guard isOn != settings.isCuppingEnabled else { return }

        settings.isCuppingEnabled = isOn
        log.record("cupping turned \(isOn ? "on" : "off") in the settings")
        save()
    }

    private func placeShapingPad(_ placement: ShapingPadPlacement) {
        guard placement != settings.shapingPadPlacement else { return }

        settings.shapingPadPlacement = placement
        log.record("shaping pad placed on the \(placement) in the settings")
        save()
    }

    private func resizeShapingPad(to fraction: Double) {
        let size = ShapingPadSize(clamping: fraction)
        guard size != settings.shapingPadSize else { return }

        settings.shapingPadSize = size
        log.recordSample("shaping pad resized to \(size.fraction) of its range in the settings")
        save()
    }

    private func save() {
        repository.save(settings)
        state = presenter.present(settings)
    }
}
