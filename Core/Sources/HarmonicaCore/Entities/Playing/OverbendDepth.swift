public struct OverbendDepth: EffectDepth, Equatable {
    public static let none = OverbendDepth(clamping: 0)

    public let fraction: Double

    public init(fraction: Double) {
        self.fraction = fraction
    }
}
