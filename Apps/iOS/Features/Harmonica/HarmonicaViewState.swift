enum HarmonicaViewState: Equatable {
    case preparingSound
    case ready(PlayableHarmonica)
    case soundUnavailable(String)
}

// MARK: - PlayableHarmonica

struct PlayableHarmonica: Equatable {
    let holes: [HoleViewState]
    let key: KeyViewState
    let style: PlayingStyleViewState
    let demo: DemoViewState
    let toneShaping: ToneShapingViewState
}

// MARK: - PlayingStyleViewState

struct PlayingStyleViewState: Equatable {
    let fingersLabel: String
    let mouthLabel: String
    let isMouth: Bool
}

// MARK: - DemoViewState

struct DemoViewState: Equatable {
    let label: String
}

// MARK: - ToneShapingViewState

struct ToneShapingViewState: Equatable {
    let overbendLabel: String
    let bendLabel: String
    let vibratoLabel: String
    let overbendIsAvailable: Bool
    let bendIsAvailable: Bool
}

// MARK: - HoleViewState

struct HoleViewState: Equatable, Identifiable {
    let id: Int
    let label: String
    let note: String
    let effect: String
    let sounding: Breath?
}

// MARK: - KeyViewState

struct KeyViewState: Equatable {
    let label: String
    let position: Double
    let highestPosition: Double
}
