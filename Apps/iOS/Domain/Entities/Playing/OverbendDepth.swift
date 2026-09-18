struct OverbendDepth: EffectDepth, Equatable {
    static let none = OverbendDepth(clamping: 0)

    let fraction: Double
}
