struct ShapingPadSize: Equatable {
    static let atFirstLaunch = ShapingPadSize(clamping: 0.4)

    let fraction: Double

    init(clamping fraction: Double) {
        self.fraction = min(1, max(0, fraction))
    }
}
