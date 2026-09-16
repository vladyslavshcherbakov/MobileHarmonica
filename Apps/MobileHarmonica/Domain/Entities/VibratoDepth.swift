struct VibratoDepth: Equatable {
    static let off = VibratoDepth(clamping: 0)

    let fraction: Double

    init(clamping fraction: Double) {
        self.fraction = fraction.isFinite ? min(1, max(0, fraction)) : 0
    }
}
