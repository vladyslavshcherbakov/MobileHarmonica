struct BendDepth: EffectDepth, Equatable {
    static let unbent = BendDepth(clamping: 0)

    let fraction: Double
}
