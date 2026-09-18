enum HarmonicaPosition {
    case first
    case second
    case third

    var semitonesAboveTheHarmonica: Int {
        switch self {
        case .first: 0
        case .second: 7
        case .third: 2
        }
    }
}
