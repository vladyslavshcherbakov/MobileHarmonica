public struct Score: Equatable {
    public let name: String
    public let key: HarmonicaKey
    public let position: HarmonicaPosition
    public let beatsPerMinute: Double
    public let events: [ScoreEvent]

    public init(
        name: String,
        key: HarmonicaKey,
        position: HarmonicaPosition,
        beatsPerMinute: Double,
        events: [ScoreEvent]
    ) {
        self.name = name
        self.key = key
        self.position = position
        self.beatsPerMinute = beatsPerMinute
        self.events = events
    }

    public var harmonicaKey: HarmonicaKey {
        HarmonicaKey(transposedBy: key.semitonesFromC - position.semitonesAboveTheHarmonica)
    }

    public var secondsPerBeat: Double {
        60 / beatsPerMinute
    }

    public static let tunes: [Score] = [
        .bluesStrain, .slowDrag, .hammerSong, .foxChase,
        .neseHaliaVodu, .oiPidVyshneiu, .naIvanaNaKupala
    ]
}

// MARK: - ScoreEvent

public enum ScoreEvent: Equatable {
    case note(ScoreNote)
    case rest(beats: Double)

    public var beats: Double {
        switch self {
        case .note(let note): note.beats
        case .rest(let beats): beats
        }
    }
}

// MARK: - ScoreNote

public struct ScoreNote: Equatable {
    public let holes: [Hole]
    public let breath: Breath
    public let beats: Double
    public var bentBySemitones = 0.0
    public var isOverbent = false
    public var vibrato = 0.0
    public var slideFrom: Hole?
    public var shakenWith: Hole?
    public var bendEndsAtSemitones: Double?

    public init(
        holes: [Hole],
        breath: Breath,
        beats: Double,
        bentBySemitones: Double = 0,
        isOverbent: Bool = false,
        vibrato: Double = 0,
        slideFrom: Hole? = nil,
        shakenWith: Hole? = nil,
        bendEndsAtSemitones: Double? = nil
    ) {
        self.holes = holes
        self.breath = breath
        self.beats = beats
        self.bentBySemitones = bentBySemitones
        self.isOverbent = isOverbent
        self.vibrato = vibrato
        self.slideFrom = slideFrom
        self.shakenWith = shakenWith
        self.bendEndsAtSemitones = bendEndsAtSemitones
    }
}
