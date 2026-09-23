public struct ScoreReading: Equatable, Sendable {
    public let score: Score
    public let playability: Playability

    public init(score: Score, playability: Playability) {
        self.score = score
        self.playability = playability
    }
}
