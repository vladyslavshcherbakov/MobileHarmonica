extension Score {
    static let hammerSong = Score(
        name: "Hammer song",
        key: .g,
        position: .second,
        beatsPerMinute: 104,
        events: hammering + octaves + slapped + hammering + closing
    )

    private static let hammering: [ScoreEvent] = [
        .draw([.one, .two], 0.75), .blow([.one, .two], 0.25),
        .draw([.one, .two], 0.75), .rest(beats: 0.25),
        .draw([.one, .two], 0.75), .blow([.one, .two], 0.25),
        .draw([.one, .two], 0.5), .rest(beats: 0.5)
    ]

    private static let octaves: [ScoreEvent] = [
        .draw([.one, .four], 1),
        .blow([.one, .four], 1),
        .draw([.one, .four], 0.75), .rest(beats: 0.25),
        .draw(.three, 1, bentBy: 1)
    ]

    private static let slapped: [ScoreEvent] = [
        .draw([.one, .two, .three], 0.15), .draw(.two, 0.85),
        .draw([.one, .two, .three], 0.15), .draw(.three, 0.85, bentBy: 1),
        .blow([.one, .two, .three], 0.15), .blow(.four, 0.85),
        .draw(.two, 0.75, vibrato: 0.6), .rest(beats: 0.25)
    ]

    private static let closing: [ScoreEvent] = [
        .draw(.three, 1, bentBy: 1, releasingTo: 0),
        .draw(.two, 1),
        .draw([.one, .two], 2, vibrato: 0.5)
    ]
}
