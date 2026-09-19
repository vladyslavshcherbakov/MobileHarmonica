public struct Playability: Equatable {
    public let unreachable: [MIDINote]
    public let bends: Int
    public let overbends: Int
    public let widestLeapInHoles: Int

    public init(unreachable: [MIDINote], bends: Int, overbends: Int, widestLeapInHoles: Int) {
        self.unreachable = unreachable
        self.bends = bends
        self.overbends = overbends
        self.widestLeapInHoles = widestLeapInHoles
    }

    public var isPerfect: Bool {
        unreachable.isEmpty
    }

    public var summary: String {
        let missed = unreachable.map(\.name).joined(separator: " ")
        return "\(bends) bends, \(overbends) overbends, widest leap \(widestLeapInHoles) holes"
            + (missed.isEmpty ? ", every note reachable" : ", out of reach: \(missed)")
    }
}
