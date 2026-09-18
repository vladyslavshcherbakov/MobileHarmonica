struct Score: Equatable {
    let key: HarmonicaKey
    let position: HarmonicaPosition
    let beatsPerMinute: Double
    let events: [ScoreEvent]

    var harmonicaKey: HarmonicaKey {
        HarmonicaKey(transposedBy: key.semitonesFromC - position.semitonesAboveTheHarmonica)
    }

    var secondsPerBeat: Double {
        60 / beatsPerMinute
    }
}

// MARK: - ScoreEvent

enum ScoreEvent: Equatable {
    case note(ScoreNote)
    case rest(beats: Double)

    var beats: Double {
        switch self {
        case .note(let note): note.beats
        case .rest(let beats): beats
        }
    }
}

// MARK: - ScoreNote

struct ScoreNote: Equatable {
    let holes: [Hole]
    let breath: Breath
    let beats: Double
    var bentBySemitones = 0.0
    var isOverbent = false
    var vibrato = 0.0
    var slideFrom: Hole?
}
