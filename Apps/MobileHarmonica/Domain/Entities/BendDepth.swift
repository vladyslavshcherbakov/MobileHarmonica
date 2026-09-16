struct BendDepth: Equatable {
    static let unbent = BendDepth(clamping: 0)

    let fraction: Double

    init(clamping fraction: Double) {
        self.fraction = fraction.isFinite ? min(1, max(0, fraction)) : 0
    }
}
