public struct PitchShaping: Equatable, Sendable {
    public static let rest = PitchShaping(clamping: 0)

    private static let overbendThreshold = 0.5

    public let fraction: Double

    // MARK: - Public

    public init(clamping value: Double) {
        fraction = ControlPrecision.quantised(value, within: -1...1)
    }

    public var bend: BendDepth {
        BendDepth(clamping: -fraction)
    }

    public var overbend: OverbendDepth {
        OverbendDepth(clamping: fraction < Self.overbendThreshold ? 0 : 1)
    }
}
