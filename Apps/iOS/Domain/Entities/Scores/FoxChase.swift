extension Score {
    static let foxChase = Score(
        name: "Fox chase",
        key: .g,
        position: .second,
        beatsPerMinute: 132,
        events: horn + gallop + whooping + gallop + baying
    )

    private static let horn: [ScoreEvent] = [
        .blow([.one, .two, .three], 1.5),
        .blow([.one, .two, .three], 0.5),
        .blow([.one, .two, .three], 2, vibrato: 0.7),
        .rest(beats: 1)
    ]

    private static let gallop: [ScoreEvent] = [
        .draw([.one, .two], 0.333), .draw([.one, .two], 0.333), .blow([.one, .two], 0.334),
        .draw([.one, .two], 0.333), .draw([.one, .two], 0.333), .blow([.one, .two], 0.334),
        .draw([.one, .two], 0.333), .draw([.one, .two], 0.333), .blow([.one, .two], 0.334),
        .draw([.one, .two], 0.333), .draw([.one, .two], 0.333), .blow([.one, .two], 0.334)
    ]

    private static let whooping: [ScoreEvent] = [
        .draw(.four, 1, shakenWith: .five),
        .draw(.five, 1, shakenWith: .six),
        .draw(.two, 1, bentBy: 2, releasingTo: 0),
        .draw(.three, 1, bentBy: 3, releasingTo: 0)
    ]

    private static let baying: [ScoreEvent] = [
        .draw(.four, 1.5, shakenWith: .five),
        .draw(.three, 1, bentBy: 3, releasingTo: 1),
        .draw(.two, 1.5, bentBy: 2, vibrato: 0.9),
        .rest(beats: 2)
    ]
}
