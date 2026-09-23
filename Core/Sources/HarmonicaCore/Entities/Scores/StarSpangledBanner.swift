public extension Score {
    static let starSpangledBanner = Score(
        name: "The Star-Spangled Banner",
        key: .c,
        position: .first,
        beatsPerMinute: 80,
        events: byTheDawnsEarlyLight + whoseBroadStripes + theRocketsRedGlare + doesThatBannerYetWave
    )

    private static let byTheDawnsEarlyLight: [ScoreEvent] = breathing(0.55, verse)

    private static let whoseBroadStripes: [ScoreEvent] = breathing(0.6, verse)

    private static let verse: [ScoreEvent] = [
        .blow(.three, 0.5), .blow(.two, 0.5),
        .blow(.one, 1), .blow(.two, 1), .blow(.three, 1),
        .blow(cMajorUnderC5, 2, vibrato: 0.4, slideFrom: .one), .blow(.five, 0.5), .draw(.four, 0.5),
        .blow(cMajorUnderC5, 1), .blow(.two, 1), .draw(.two, 1, bentBy: 1),
        .blow(cMajorUnderG4, 2, vibrato: 0.4), .blow(.three, 0.5), .blow(.three, 0.5),
        .blow(cMajorUnderE5, 1.5), .draw(.four, 0.5), .blow(.four, 1),
        .draw(gMajorUnderB4, 2, vibrato: 0.4), .draw(.three, 0.5, bentBy: 2), .draw(.three, 0.5),
        .blow(cMajorUnderC5, 1), .blow(.four, 1), .blow(.three, 1),
        .blow(.two, 1), .blow(lowOctaveOfC, 1)
    ]

    private static let theRocketsRedGlare: [ScoreEvent] = breathing(0.75, [
        .blow(.five, 0.5), .blow(.five, 0.5),
        .blow(cMajorUnderE5, 1), .draw(gSeventhUnderF5, 1), .blow(cMajorUnderG5, 1)
    ]) + breathing(0.85, [
        .blow(octaveOfG, 2, vibrato: 0.5, slideFrom: .four), .draw(.five, 0.5), .blow(.five, 0.5),
        .draw(gMajorUnderD5, 1), .blow(.five, 1), .draw(.five, 1),
        .draw(gSeventhUnderF5, 2, vibrato: 0.5), .draw(.five, 1)
    ]) + breathing(0.7, [
        .blow(cMajorUnderE5, 1.5), .draw(.four, 0.5), .blow(.four, 1),
        .draw(gMajorUnderB4, 2, vibrato: 0.4), .draw(.three, 0.5, bentBy: 2), .draw(.three, 0.5),
        .blow(cMajorUnderC5, 1), .blow(.two, 1), .draw(.two, 1, bentBy: 1),
        .blow(cMajorUnderG4, 2, vibrato: 0.5)
    ])

    private static let doesThatBannerYetWave: [ScoreEvent] = breathing(0.5, [
        .blow(.three, 1),
        .blow(cMajorUnderC5, 1), .blow(.four, 1), .blow(.four, 0.5), .draw(.three, 0.5)
    ]) + breathing(0.6, [
        .draw(.three, 1, bentBy: 2), .draw(.three, 1, bentBy: 2), .draw(.three, 1, bentBy: 2),
        .draw(gMajorUnderD5, 1), .draw(.five, 0.5), .blow(.five, 0.5), .draw(.four, 0.5), .blow(.four, 0.5)
    ]) + breathing(0.7, [
        .blow(cMajorUnderC5, 1), .draw(gMajorUnderB4, 2, vibrato: 0.7)
    ]) + breathing(0.8, [
        .blow(.three, 0.5), .blow(.three, 0.5),
        .blow(cMajorUnderC5, 1.5), .draw(.four, 0.5), .blow(.five, 0.5), .draw(.five, 0.5)
    ]) + breathing(1, [
        .blow(octaveOfG, 4, vibrato: 0.7, slideFrom: .one)
    ]) + breathing(0.85, [
        .blow(.four, 0.5), .draw(.four, 0.5),
        .blow(cMajorUnderE5, 1.5), .draw(.five, 0.5), .draw(.four, 1)
    ]) + breathing(0.9, [
        .blow(octaveOfC, 3, vibrato: 0.6, slideFrom: .one)
    ])

    private static let cMajorUnderG4: [Hole] = [.three, .one, .two]
    private static let cMajorUnderC5: [Hole] = [.four, .two, .three]
    private static let cMajorUnderE5: [Hole] = [.five, .three, .four]
    private static let cMajorUnderG5: [Hole] = [.six, .four, .five]
    private static let gMajorUnderB4: [Hole] = [.three, .one, .two]
    private static let gMajorUnderD5: [Hole] = [.four, .two, .three]
    private static let gSeventhUnderF5: [Hole] = [.five, .three, .four]
    private static let lowOctaveOfC: [Hole] = [.one, .four]
    private static let octaveOfG: [Hole] = [.six, .three]
    private static let octaveOfC: [Hole] = [.four, .seven]

    private static func breathing(_ intensity: Double, _ events: [ScoreEvent]) -> [ScoreEvent] {
        events.map { event in
            guard case .note(var note) = event else { return event }

            note.breathIntensity = intensity
            return .note(note)
        }
    }
}
