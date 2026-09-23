public extension Score {
    static let oiPidVyshneiu = Score(
        name: "Oi pid vyshneiu",
        key: .d,
        position: .third,
        beatsPerMinute: 96,
        events: underTheCherryTree + [.rest(beats: 1)] + theOldManStanding
    )

    private static let underTheCherryTree: [ScoreEvent] = [
        .draw(.six, 1), .draw(.six, 1), .draw(.six, 1),
        .blow(.six, 1), .draw(.five, 2, vibrato: 0.4), .blow(.six, 1),
        .blow(.six, 1), .blow(.six, 1), .draw(.five, 1),
        .blow(.five, 2, vibrato: 0.4)
    ]

    private static let theOldManStanding: [ScoreEvent] = [
        .draw(.four, 1), .blow(.five, 1), .draw(.five, 1),
        .blow(.six, 1), .draw(.six, 2, vibrato: 0.4), .draw(.six, 1),
        .blow(.six, 1), .draw(.five, 1), .blow(.five, 1),
        .draw(.four, 2, vibrato: 0.4)
    ]
}
