public struct CupDepth: EffectDepth, Equatable {
    public static let open = CupDepth(clamping: 0)

    public let fraction: Double

    public init(fraction: Double) {
        self.fraction = fraction
    }
}
