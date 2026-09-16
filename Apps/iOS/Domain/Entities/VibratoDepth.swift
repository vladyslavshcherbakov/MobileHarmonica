struct VibratoDepth: EffectDepth, Equatable {
    static let off = VibratoDepth(clamping: 0)

    let fraction: Double
}
