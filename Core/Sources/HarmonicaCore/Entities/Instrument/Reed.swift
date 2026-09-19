public struct Reed: Equatable {
    public let hole: Hole
    public let breath: Breath

    public init(hole: Hole, breath: Breath) {
        self.hole = hole
        self.breath = breath
    }
}
