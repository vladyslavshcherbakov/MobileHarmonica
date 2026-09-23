public protocol EffectDepth: Sendable {
    var fraction: Double { get }

    init(fraction: Double)
}

// MARK: - EffectDepth + clamping

public extension EffectDepth {
    init(clamping value: Double) {
        self.init(fraction: ControlPrecision.quantised(value))
    }
}
