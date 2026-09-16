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
        guard (0...1).contains(position.fractionFromLeftEdge) else { return nil }

        let holeCount = Hole.allCases.count
        let index = min(holeCount - 1, Int(position.fractionFromLeftEdge * Double(holeCount)))
        self = Hole.allCases[index]
    }
}
