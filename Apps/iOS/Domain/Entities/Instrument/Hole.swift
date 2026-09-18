enum Hole: Int, CaseIterable {
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

    var number: Int {
        rawValue
    }
}

// MARK: - Hole + PositionOnHarmonica

extension Hole {
    init?(at position: PositionOnHarmonica) {
        guard position.isOnTheHarmonica else { return nil }

        self = Hole.allCases[Hole.nearestIndex(atFraction: position.fractionFromLeftEdge)]
    }

    static func allCovered(by position: PositionOnHarmonica) -> [Hole] {
        guard position.isOnTheHarmonica else { return [] }

        let leftmost = nearestIndex(atFraction: position.fractionFromLeftEdge - position.fractionCoveredEitherSide)
        let rightmost = nearestIndex(atFraction: position.fractionFromLeftEdge + position.fractionCoveredEitherSide)
        return (leftmost...rightmost).map { allCases[$0] }
    }

    private static func nearestIndex(atFraction fraction: Double) -> Int {
        let withinTheStrip = min(1, max(0, fraction))
        return min(allCases.count - 1, Int(withinTheStrip * Double(allCases.count)))
    }
}

// MARK: - PositionOnHarmonica + Hole

extension PositionOnHarmonica {
    var isOnTheHarmonica: Bool {
        (0...1).contains(fractionFromLeftEdge)
    }

    var coveredHoleWidths: Double {
        2 * fractionCoveredEitherSide * Double(Hole.allCases.count)
    }
}
