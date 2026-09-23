public enum MouthWidth: Int, CaseIterable, Sendable {
    case oneHole = 1
    case twoHoles
    case threeHoles
    case fourHoles

    public var holes: Int {
        rawValue
    }
}
