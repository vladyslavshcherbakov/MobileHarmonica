protocol EffectDepth {
    var fraction: Double { get }

    init(fraction: Double)
}

// MARK: - EffectDepth + clamping

extension EffectDepth {
    init(clamping value: Double) {
        self.init(fraction: ControlPrecision.quantised(value))
    }
}
