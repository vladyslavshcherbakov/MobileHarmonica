public extension Score {
    static let starSpangledBanner = Score(
        name: "The Star-Spangled Banner",
        key: .c,
        position: .first,
        beatsPerMinute: 80,
        events: byTheDawnsEarlyLight + whoseBroadStripes + theRocketsRedGlare + doesThatBannerYetWave
    )

    private static let byTheDawnsEarlyLight: [ScoreEvent] = breathing(0.65, [
        .blow(.three, 0.5), .blow(.two, 0.5),
        .blow(.one, 1), .blow(.two, 1), .blow(.three, 1),
        .blow(.four, 2, vibrato: 0.4), .blow(.five, 0.5), .draw(.four, 0.5),
        .blow(.four, 1), .blow(.two, 1), .draw(.two, 1, bentBy: 1),
        .blow(.three, 2, vibrato: 0.4), .blow(.three, 0.5), .blow(.three, 0.5),
        .blow(.five, 1.5), .draw(.four, 0.5), .blow(.four, 1),
        .draw(.three, 2, vibrato: 0.4), .draw(.three, 0.5, bentBy: 2), .draw(.three, 0.5),
        .blow(.four, 1), .blow(.four, 1), .blow(.three, 1),
        .blow(.two, 1), .blow(.one, 1)
    ])

    private static let whoseBroadStripes: [ScoreEvent] = breathing(0.7, [
        .blow(.three, 0.5), .blow(.two, 0.5),
        .blow(.one, 1), .blow(.two, 1), .blow(.three, 1),
        .blow(.four, 2, vibrato: 0.4), .blow(.five, 0.5), .draw(.four, 0.5),
        .blow(.four, 1), .blow(.two, 1), .draw(.two, 1, bentBy: 1),
        .blow(.three, 2, vibrato: 0.4), .blow(.three, 0.5), .blow(.three, 0.5),
        .blow(.five, 1.5), .draw(.four, 0.5), .blow(.four, 1),
        .draw(.three, 2, vibrato: 0.4), .draw(.three, 0.5, bentBy: 2), .draw(.three, 0.5),
        .blow(.four, 1), .blow(.four, 1), .blow(.three, 1),
        .blow(.two, 1), .blow(.one, 1)
    ])

    private static let theRocketsRedGlare: [ScoreEvent] = breathing(0.85, [
        .blow(.five, 0.5), .blow(.five, 0.5),
        .blow(.five, 1), .draw(.five, 1), .blow(.six, 1),
        .blow(.six, 2, vibrato: 0.5), .draw(.five, 0.5), .blow(.five, 0.5),
        .draw(.four, 1), .blow(.five, 1), .draw(.five, 1),
        .draw(.five, 2, vibrato: 0.5), .draw(.five, 1)
    ]) + breathing(0.8, [
        .blow(.five, 1.5), .draw(.four, 0.5), .blow(.four, 1),
        .draw(.three, 2, vibrato: 0.4), .draw(.three, 0.5, bentBy: 2), .draw(.three, 0.5),
        .blow(.four, 1), .blow(.two, 1), .draw(.two, 1, bentBy: 1)
    ]) + breathing(0.75, [
        .blow(.three, 2, vibrato: 0.5)
    ])

    private static let doesThatBannerYetWave: [ScoreEvent] = breathing(0.6, [
        .blow(.three, 1),
        .blow(.four, 1), .blow(.four, 1), .blow(.four, 0.5), .draw(.three, 0.5)
    ]) + breathing(0.7, [
        .draw(.three, 1, bentBy: 2), .draw(.three, 1, bentBy: 2), .draw(.three, 1, bentBy: 2),
        .draw(.four, 1), .draw(.five, 0.5), .blow(.five, 0.5), .draw(.four, 0.5), .blow(.four, 0.5)
    ]) + breathing(0.8, [
        .blow(.four, 1), .draw(.three, 2, vibrato: 0.7)
    ]) + breathing(0.85, [
        .blow(.three, 0.5), .blow(.three, 0.5),
        .blow(.four, 1.5), .draw(.four, 0.5), .blow(.five, 0.5), .draw(.five, 0.5)
    ]) + breathing(1, [
        .blow(.six, 4, vibrato: 0.7)
    ]) + breathing(0.9, [
        .blow(.four, 0.5), .draw(.four, 0.5),
        .blow(.five, 1.5), .draw(.five, 0.5), .draw(.four, 1)
    ]) + breathing(0.85, [
        .blow(.four, 3, vibrato: 0.6)
    ])

    private static func breathing(_ intensity: Double, _ events: [ScoreEvent]) -> [ScoreEvent] {
        events.map { event in
            guard case .note(var note) = event else { return event }

            note.breathIntensity = intensity
            return .note(note)
        }
    }
}
