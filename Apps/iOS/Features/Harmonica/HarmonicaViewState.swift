enum HarmonicaViewState: Equatable {
    case preparingSound
    case ready(Playable)
    case soundUnavailable(String)

    // MARK: - Playable

    struct Playable: Equatable {
        let holes: [Hole]
        let key: Key
        let fingerMarks: FingerMarks
        let cup: Cup?
        let demo: Demo
        let toneShaping: ToneShaping
        let square: Square
    }

    // MARK: - Hole

    struct Hole: Equatable, Identifiable {
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

    // MARK: - Key

    struct Key: Equatable {
        let label: String
        let position: Double
        let highestPosition: Double
    }

    // MARK: - FingerMarks

    struct FingerMarks: Equatable {
        let isDrawnAtTheContactWidth: Bool
        let drawsOnlyTheDecidingFinger: Bool
    }

    // MARK: - Cup

    struct Cup: Equatable {
        let label: String
        let closed: Double
    }

    // MARK: - Demo

    struct Demo: Equatable {
        let label: String
        let tunes: [Tune]
        let isPlaying: Bool
    }

    // MARK: - Tune

    struct Tune: Equatable, Identifiable {
        let id: Int
        let name: String
    }

    // MARK: - ToneShaping

    struct ToneShaping: Equatable {
        let overbendLabel: String
        let bendLabel: String
        let vibratoLabel: String
        let isOverbendAvailable: Bool
        let isBendAvailable: Bool
    }

    // MARK: - Square

    struct Square: Equatable {
        let placement: SquarePlacement
        let size: SquareSize
    }
}
