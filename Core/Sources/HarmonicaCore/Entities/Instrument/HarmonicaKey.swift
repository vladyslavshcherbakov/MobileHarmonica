public enum HarmonicaKey: Int, CaseIterable {
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

    public static let lowest = HarmonicaKey.g
    public static let highestSliderPosition = HarmonicaKey.allCases.count - 1

    public init(nearestSliderPosition position: Int) {
        self = Self.allCases[min(Self.highestSliderPosition, max(0, position))]
    }

    public init(transposedBy semitones: Int) {
        let semitonesAboveTheLowest = semitones - Self.lowest.rawValue
        self = Self.allCases[(semitonesAboveTheLowest % 12 + 12) % 12]
    }

    public var semitonesFromC: Int {
        rawValue
    }

    public var sliderPosition: Int {
        rawValue - Self.lowest.rawValue
    }
}
