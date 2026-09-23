public extension Score {
    static let neseHaliaVodu = Score(
        name: "Nese Halia vodu",
        key: .a,
        position: .third,
        beatsPerMinute: 80,
        events: carryingTheWater + [.rest(beats: 1)] + ivankoFollowing
    )

    private static let carryingTheWater: [ScoreEvent] = [
        .draw(.four, 1), .draw(.four, 1), .draw(.five, 1),
        .draw(.five, 1), .draw(.six, 2, vibrato: 0.6), .draw(.six, 1),
        .blow(.six, 1), .draw(.five, 1), .blow(.five, 1),
        .draw(.four, 2, vibrato: 0.6)
    ]

    private static let ivankoFollowing: [ScoreEvent] = [
        .draw(.four, 1), .draw(.four, 1), .draw(.five, 1),
        .draw(.five, 1), .draw(.six, 2, vibrato: 0.6), .draw(.six, 1),
        .blow(.six, 1), .draw(.five, 1), .blow(.five, 1),
        .draw(.four, 2, vibrato: 0.6)
    ]
}
