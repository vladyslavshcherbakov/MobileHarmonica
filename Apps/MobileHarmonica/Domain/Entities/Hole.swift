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

// MARK: - Hole + PositionAlongHarmonica

extension Hole {
    init?(at position: PositionAlongHarmonica) {
        guard (0...1).contains(position.fraction) else { return nil }

        let holeCount = Hole.allCases.count
        let index = min(holeCount - 1, Int(position.fraction * Double(holeCount)))
        self = Hole.allCases[index]
    }
}
