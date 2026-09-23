public struct Playability: Equatable, Sendable {
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
}
