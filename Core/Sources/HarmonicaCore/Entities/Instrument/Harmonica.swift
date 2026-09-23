public struct Harmonica: Equatable, Sendable {
    public let key: HarmonicaKey
    public let style: PlayingStyle
    public let mouth: MouthMeasure
    public let cup: CupDepth
    public let sounding: [Hole: SoundingReed]

    public init(
        key: HarmonicaKey,
        style: PlayingStyle,
        mouth: MouthMeasure,
        cup: CupDepth,
        sounding: [Hole: SoundingReed]
    ) {
        self.key = key
        self.style = style
        self.mouth = mouth
        self.cup = cup
        self.sounding = sounding
    }

    public var breath: Breath? {
        sounding.values.first?.breath
    }

    public var canBend: Bool {
        sounding.values.contains(where: \.canBend)
    }

    public var canOverbend: Bool {
        sounding.values.contains(where: \.canOverbend)
    }
}
