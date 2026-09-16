protocol EffectDepth {
    var fraction: Double { get }

    init(fraction: Double)
}

// MARK: - EffectDepth + clamping

extension EffectDepth {
    init(clamping value: Double) {
        self.init(fraction: value.isFinite ? min(1, max(0, value)) : 0)
    }
}
