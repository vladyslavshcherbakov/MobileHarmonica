struct CupDepth: EffectDepth, Equatable {
    static let open = CupDepth(clamping: 0)

    let fraction: Double
}
