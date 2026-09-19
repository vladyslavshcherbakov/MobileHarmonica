public struct VibratoDepth: EffectDepth, Equatable {
    public static let off = VibratoDepth(clamping: 0)

    public let fraction: Double

    public init(fraction: Double) {
        self.fraction = fraction
    }
}
