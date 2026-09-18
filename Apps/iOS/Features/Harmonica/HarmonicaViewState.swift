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
    let fingerMarks: FingerMarksViewState
    let cup: CupViewState
    let demo: DemoViewState
    let toneShaping: ToneShapingViewState
}

// MARK: - PlayingStyleViewState

struct PlayingStyleViewState: Equatable {
    let label: String
    let choices: [PlayingStyleChoiceViewState]
}

// MARK: - PlayingStyleChoiceViewState

struct PlayingStyleChoiceViewState: Equatable, Identifiable {
    let id: PlayingStyleChoice
    let name: String
}

// MARK: - PlayingStyleChoice

enum PlayingStyleChoice: Hashable {
    case severalFingersSeveralNotes
    case severalFingersOneNote
    case oneFingerSeveralNotes
}

// MARK: - CupViewState

struct CupViewState: Equatable {
    let label: String
    let closed: Double
}

// MARK: - FingerMarksViewState

struct FingerMarksViewState: Equatable {
    let atTheContactWidth: Bool
    let onlyTheDecidingFinger: Bool
}

// MARK: - DemoViewState

struct DemoViewState: Equatable {
    let label: String
    let tunes: [TuneViewState]
    let isPlaying: Bool
}

// MARK: - TuneViewState

struct TuneViewState: Equatable, Identifiable {
    let id: Int
    let name: String
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
    let lit: LitHalf?
}

// MARK: - LitHalf

enum LitHalf: Hashable {
    case top
    case bottom
}

// MARK: - KeyViewState

struct KeyViewState: Equatable {
    let label: String
    let position: Double
    let highestPosition: Double
}
