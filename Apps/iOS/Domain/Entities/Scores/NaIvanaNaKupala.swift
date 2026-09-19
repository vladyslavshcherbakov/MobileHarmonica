extension Score {
    static let naIvanaNaKupala = Score(
        name: "Na Ivana na Kupala",
        key: .g,
        position: .first,
        beatsPerMinute: 104,
        events: callingOverTheFire + [.rest(beats: 1)] + theAnswerBack
    )

    private static let callingOverTheFire: [ScoreEvent] = [
        .blow(.six, 1), .blow(.six, 1), .draw(.five, 1),
        .blow(.five, 1), .draw(.four, 2, vibrato: 0.5), .blow(.four, 1),
        .draw(.four, 1), .blow(.five, 1), .draw(.five, 1),
        .blow(.six, 2, vibrato: 0.5)
    ]

    private static let theAnswerBack: [ScoreEvent] = [
        .blow(.six, 1), .draw(.six, 1), .blow(.six, 1),
        .draw(.five, 1), .blow(.five, 2, vibrato: 0.5), .draw(.four, 1),
        .blow(.five, 1), .draw(.four, 1), .blow(.four, 1),
        .blow(.four, 2, vibrato: 0.5)
    ]
}
