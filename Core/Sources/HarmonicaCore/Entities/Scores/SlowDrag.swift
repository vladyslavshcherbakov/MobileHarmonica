public extension Score {
    static let slowDrag = Score(
        name: "Slow drag",
        key: .g,
        position: .second,
        beatsPerMinute: 66,
        events: scooped + answered + climbing + settling
    )

    private static let scooped: [ScoreEvent] = [
        .draw(.three, 2, bentBy: 2, releasingTo: 0),
        .blow(.four, 1),
        .draw(.four, 1, bentBy: 1, releasingTo: 0),
        .draw(.three, 3, vibrato: 0.8),
        .rest(beats: 1)
    ]

    private static let answered: [ScoreEvent] = [
        .draw(.two, 2, bentBy: 2, releasingTo: 0, vibrato: 0.5),
        .blow(.four, 1),
        .draw(.four, 1),
        .blow(.five, 3, vibrato: 0.6),
        .rest(beats: 1)
    ]

    private static let climbing: [ScoreEvent] = [
        .blow(.four, 1, slideFrom: .two),
        .draw(.four, 1, bentBy: 1, releasingTo: 0),
        .blow(.five, 1),
        .draw(.five, 1),
        .blow(.six, 2, vibrato: 0.7),
        .draw(.five, 1, shakenWith: .six),
        .rest(beats: 1)
    ]

    private static let settling: [ScoreEvent] = [
        .draw(.four, 1),
        .blow(.four, 1),
        .draw(.three, 2, bentBy: 1, releasingTo: 0),
        .draw(.two, 3, vibrato: 0.9),
        .rest(beats: 1)
    ]
}
