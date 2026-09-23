struct SettingsViewState: Equatable {
    let title: String
    let style: Style
    let cupping: Cupping
    let squarePlacement: Placement
    let squareSize: Size

    // MARK: - Style

    struct Style: Equatable {
        let label: String
        let chosen: StyleChoice
        let choices: [StyleOption]
    }

    // MARK: - StyleOption

    struct StyleOption: Equatable, Identifiable {
        let id: StyleChoice
        let name: String
    }

    // MARK: - StyleChoice

    enum StyleChoice: Hashable {
        case severalFingersSeveralNotes
        case severalFingersOneNote
        case oneFingerSeveralNotes
    }

    // MARK: - Cupping

    struct Cupping: Equatable {
        let label: String
        let isOn: Bool
    }

    // MARK: - Placement

    struct Placement: Equatable {
        let label: String
        let chosen: SquarePlacement
        let choices: [PlacementOption]
    }

    // MARK: - PlacementOption

    struct PlacementOption: Equatable, Identifiable {
        let id: SquarePlacement
        let name: String
    }

    // MARK: - Size

    struct Size: Equatable {
        let label: String
        let fraction: Double
    }
}
