struct SquareSize: Equatable {
    static let atFirstLaunch = SquareSize(clamping: 0.4)

    let fraction: Double

    init(clamping fraction: Double) {
        self.fraction = min(1, max(0, fraction))
    }
}
