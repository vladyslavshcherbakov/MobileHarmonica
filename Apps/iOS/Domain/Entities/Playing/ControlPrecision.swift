enum ControlPrecision {
    static let step = 0.01

    static func quantised(_ value: Double) -> Double {
        quantised(value, within: 0...1)
    }

    static func quantised(_ value: Double, within range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return 0 }

        return (min(range.upperBound, max(range.lowerBound, value)) / step).rounded() * step
    }
}
