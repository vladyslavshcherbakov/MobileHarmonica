public struct PositionOnHarmonica: Equatable {
    public let fractionFromLeftEdge: Double
    public let fractionAboveCentreLine: Double
    public var fractionCoveredEitherSide = 0.0

    public init(
        fractionFromLeftEdge: Double,
        fractionAboveCentreLine: Double,
        fractionCoveredEitherSide: Double = 0
    ) {
        self.fractionFromLeftEdge = fractionFromLeftEdge
        self.fractionAboveCentreLine = fractionAboveCentreLine
        self.fractionCoveredEitherSide = fractionCoveredEitherSide
    }

    public static func topmost(of positions: [PositionOnHarmonica]) -> PositionOnHarmonica? {
        positions.max { $0.fractionAboveCentreLine < $1.fractionAboveCentreLine }
    }
}
