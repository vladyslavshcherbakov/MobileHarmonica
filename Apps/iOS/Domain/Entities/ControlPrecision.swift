enum ControlPrecision {
    static let step = 0.01

    static func quantised(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }

        return (min(1, max(0, value)) / step).rounded() * step
    }
}
