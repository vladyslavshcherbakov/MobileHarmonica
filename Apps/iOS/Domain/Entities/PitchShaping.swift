struct PitchShaping: Equatable {
    static let rest = PitchShaping(clamping: 0)

    private static let snapThreshold = 0.5

    let fraction: Double

    // MARK: - Public

    init(clamping value: Double) {
        fraction = ControlPrecision.quantised(value, within: -1...1)
    }

    var bend: BendDepth {
        BendDepth(clamping: -fraction)
    }

    func overbend(_ style: OverbendStyle) -> OverbendDepth {
        switch style {
        case .smooth: OverbendDepth(clamping: fraction)
        case .snap: OverbendDepth(clamping: fraction < Self.snapThreshold ? 0 : 1)
        }
    }
}
