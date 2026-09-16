enum HarmonicaKey: Int, CaseIterable {
    case g = -5
    case aFlat = -4
    case a = -3
    case bFlat = -2
    case b = -1
    case c = 0
    case dFlat = 1
    case d = 2
    case eFlat = 3
    case e = 4
    case f = 5
    case fSharp = 6

    static let lowest = HarmonicaKey.g
    static let highestPosition = HarmonicaKey.allCases.count - 1

    init(nearestPosition position: Int) {
        self = Self.allCases[min(Self.highestPosition, max(0, position))]
    }

    var semitonesFromC: Int {
        rawValue
    }

    var position: Int {
        rawValue - Self.lowest.rawValue
    }
}
