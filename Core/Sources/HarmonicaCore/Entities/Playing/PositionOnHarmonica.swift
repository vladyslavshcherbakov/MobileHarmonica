public struct PositionOnHarmonica: Equatable, Sendable {
    private static let slackAcrossTheBoundary = 0.06

    public let fractionFromLeftEdge: Double
    public let fractionAboveCentreLine: Double
    public var fractionCoveredEitherSide = 0.0

    // MARK: - Public

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

    public var isOnTheHarmonica: Bool {
        (0...1).contains(fractionFromLeftEdge)
    }

    public var isCrossingTheBreathBoundary: Bool {
        abs(fractionAboveCentreLine) < Self.slackAcrossTheBoundary
    }

    public var coveredHoleWidths: Double {
        2 * fractionCoveredEitherSide * Double(Hole.allCases.count)
    }
}
