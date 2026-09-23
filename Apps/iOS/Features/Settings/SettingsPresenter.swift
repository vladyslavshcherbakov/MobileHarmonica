import HarmonicaCore

struct SettingsPresenter {
    private static let title = "Settings"
    private static let styleLabel = "Playing style"
    private static let cuppingLabel = "Cup the hands by leaning the phone"
    private static let placementLabel = "Square"
    private static let sizeLabel = "Square size"

    // MARK: - Public

    func present(_ settings: PlayerSettings) -> SettingsViewState {
        SettingsViewState(
            title: Self.title,
            style: Self.styleState(settings.style),
            cupping: SettingsViewState.Cupping(label: Self.cuppingLabel, isOn: settings.isCuppingEnabled),
            squarePlacement: Self.placementState(settings.squarePlacement),
            squareSize: SettingsViewState.Size(label: Self.sizeLabel, fraction: settings.squareSize.fraction)
        )
    }

    // MARK: - Private

    private static func styleState(_ style: PlayingStyle) -> SettingsViewState.Style {
        SettingsViewState.Style(
            label: styleLabel,
            chosen: choice(of: style),
            choices: PlayingStyle.allCases.map { SettingsViewState.StyleOption(id: choice(of: $0), name: name(of: $0)) }
        )
    }

    private static func choice(of style: PlayingStyle) -> SettingsViewState.StyleChoice {
        switch style {
        case .severalFingersSeveralNotes: .severalFingersSeveralNotes
        case .severalFingersOneNote: .severalFingersOneNote
        case .oneFingerSeveralNotes: .oneFingerSeveralNotes
        }
    }

    private static func name(of style: PlayingStyle) -> String {
        switch style {
        case .severalFingersSeveralNotes: "Many fingers, many notes"
        case .severalFingersOneNote: "Many fingers, one note"
        case .oneFingerSeveralNotes: "One finger, many notes"
        }
    }

    private static func placementState(_ placement: SquarePlacement) -> SettingsViewState.Placement {
        SettingsViewState.Placement(
            label: placementLabel,
            chosen: placement,
            choices: SquarePlacement.allCases.map { SettingsViewState.PlacementOption(id: $0, name: name(of: $0)) }
        )
    }

    private static func name(of placement: SquarePlacement) -> String {
        switch placement {
        case .left: "Left of the holes"
        case .right: "Right of the holes"
        }
    }
}
