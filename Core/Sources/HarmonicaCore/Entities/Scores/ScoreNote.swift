public struct ScoreNote: Equatable, Sendable {
    public let holes: [Hole]
    public let breath: Breath
    public let beats: Double
    public var bentBySemitones = 0.0
    public var isOverbent = false
    public var vibrato = 0.0
    public var breathIntensity = 1.0
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
        breathIntensity: Double = 1,
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
        self.breathIntensity = breathIntensity
        self.slideFrom = slideFrom
        self.shakenWith = shakenWith
        self.bendEndsAtSemitones = bendEndsAtSemitones
    }
}
