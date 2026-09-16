enum HarmonicaViewState: Equatable {
    case preparingSound
    case ready(PlayableHarmonica)
    case soundUnavailable(String)
}

// MARK: - PlayableHarmonica

struct PlayableHarmonica: Equatable {
    let holes: [HoleViewState]
    let key: KeyViewState
    let toneShaping: ToneShapingViewState
}

// MARK: - ToneShapingViewState

struct ToneShapingViewState: Equatable {
    let bendLabel: String
    let vibratoLabel: String
}

// MARK: - HoleViewState

struct HoleViewState: Equatable, Identifiable {
    let id: Int
    let label: String
    let isSounding: Bool
}

// MARK: - KeyViewState

struct KeyViewState: Equatable {
    let label: String
    let position: Double
    let highestPosition: Double
}
