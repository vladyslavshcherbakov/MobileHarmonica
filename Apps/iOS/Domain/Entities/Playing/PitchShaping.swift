struct PitchShaping: Equatable {
    static let rest = PitchShaping(clamping: 0)

    private static let overbendThreshold = 0.5

    let fraction: Double

    // MARK: - Public

    init(clamping value: Double) {
        fraction = ControlPrecision.quantised(value, within: -1...1)
    }

    var bend: BendDepth {
        BendDepth(clamping: -fraction)
    }

    var overbend: OverbendDepth {
        OverbendDepth(clamping: fraction < Self.overbendThreshold ? 0 : 1)
    }
}
