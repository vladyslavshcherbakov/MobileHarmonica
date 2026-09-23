public enum Hole: Int, CaseIterable, Sendable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten

    private static let edgeTolerance = 1e-9

    // MARK: - Public

    public init?(at position: PositionOnHarmonica) {
        guard position.isOnTheHarmonica else { return nil }

        self = Hole.allCases[Hole.nearestIndex(atFraction: position.fractionFromLeftEdge)]
    }

    public static func allCovered(by position: PositionOnHarmonica, measuring mouth: MouthMeasure) -> [Hole] {
        guard position.isOnTheHarmonica else { return [] }

        switch mouth {
        case .theContactItself: return coveredByTheContact(at: position)
        case .holesWide(let width): return covered(by: width, centredAt: position)
        }
    }

    public var number: Int {
        rawValue
    }

    // MARK: - Private

    private static func coveredByTheContact(at position: PositionOnHarmonica) -> [Hole] {
        let leftmost = nearestIndex(atFraction: position.fractionFromLeftEdge - position.fractionCoveredEitherSide)
        let rightmost = nearestIndex(atFraction: position.fractionFromLeftEdge + position.fractionCoveredEitherSide)
        return (leftmost...rightmost).map { allCases[$0] }
    }

    private static func covered(by width: MouthWidth, centredAt position: PositionOnHarmonica) -> [Hole] {
        guard width != .oneHole else { return Hole(at: position).map { [$0] } ?? [] }

        let centre = position.fractionFromLeftEdge * Double(allCases.count)
        let span = Double(width.holes) / 2
        return allCases.indices
            .filter { isCovered(centreOfTheHole: Double($0) + 0.5, from: centre - span, to: centre + span) }
            .map { allCases[$0] }
    }

    private static func isCovered(centreOfTheHole centre: Double, from leftEdge: Double, to rightEdge: Double) -> Bool {
        centre >= leftEdge - edgeTolerance && centre < rightEdge - edgeTolerance
    }

    private static func nearestIndex(atFraction fraction: Double) -> Int {
        let withinTheStrip = min(1, max(0, fraction))
        return min(allCases.count - 1, Int(withinTheStrip * Double(allCases.count)))
    }
}
