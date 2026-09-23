public struct Score: Equatable, Sendable {
    public static let tunes: [Score] = [
        .bluesStrain, .slowDrag, .oiPidVyshneiu, .starSpangledBanner
    ]

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
}
