struct PositionOnHarmonica: Equatable {
    let fractionFromLeftEdge: Double
    let fractionAboveCentreLine: Double
    var fractionCoveredEitherSide = 0.0

    static func topmost(of positions: [PositionOnHarmonica]) -> PositionOnHarmonica? {
        positions.max { $0.fractionAboveCentreLine < $1.fractionAboveCentreLine }
    }
}
