public struct BendDepth: EffectDepth, Equatable {
    public static let unbent = BendDepth(clamping: 0)

    public let fraction: Double

    public init(fraction: Double) {
        self.fraction = fraction
    }
}
