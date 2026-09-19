public enum MouthWidth: Int, CaseIterable {
    case oneHole = 1
    case twoHoles
    case threeHoles
    case fourHoles

    public var holes: Int {
        rawValue
    }
}

// MARK: - MouthMeasure

public enum MouthMeasure: Equatable {
    case theContactItself
    case holesWide(MouthWidth)
}
