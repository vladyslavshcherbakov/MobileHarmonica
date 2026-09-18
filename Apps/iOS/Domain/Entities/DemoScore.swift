extension Score {
    static let demo = Score(
        key: .c,
        beatsPerMinute: 110,
        events: odeToJoy + [.rest(beats: 2)] + blues + [.rest(beats: 2)] + overblown
    )

    private static let odeToJoy: [ScoreEvent] = [
        blow(.five, 1), blow(.five, 1), draw(.five, 1), blow(.six, 1),
        blow(.six, 1), draw(.five, 1), blow(.five, 1), draw(.four, 1),
        blow(.four, 1), blow(.four, 1), draw(.four, 1), blow(.five, 1),
        blow(.five, 1.5), draw(.four, 0.5), draw(.four, 2),

        blow(.five, 1), blow(.five, 1), draw(.five, 1), blow(.six, 1),
        blow(.six, 1), draw(.five, 1), blow(.five, 1), draw(.four, 1),
        blow(.four, 1), blow(.four, 1), draw(.four, 1), blow(.five, 1),
        draw(.four, 1.5), blow(.four, 0.5), blow(.four, 2)
    ]

    private static let blues: [ScoreEvent] = [
        draw(.two, 0.5), draw(.three, 0.5, bentBy: 1), blow(.four, 0.5),
        draw(.three, 0.5, bentBy: 1), draw(.two, 2, vibrato: 0.8),
        .rest(beats: 0.5),
        draw(.four, 0.5), blow(.four, 0.5), draw(.three, 0.5, bentBy: 1),
        draw(.two, 2, vibrato: 0.8)
    ]

    private static let overblown: [ScoreEvent] = [
        blow(.six, 0.5), overblow(.six, 0.5), draw(.six, 0.5), blow(.six, 0.5),
        draw(.five, 1), draw(.four, 2, vibrato: 0.6)
    ]

    private static func blow(_ hole: Hole, _ beats: Double) -> ScoreEvent {
        .note(ScoreNote(hole: hole, breath: .blow, beats: beats))
    }

    private static func draw(
        _ hole: Hole,
        _ beats: Double,
        bentBy semitones: Double = 0,
        vibrato: Double = 0
    ) -> ScoreEvent {
        .note(
            ScoreNote(
                hole: hole,
                breath: .draw,
                beats: beats,
                bentBySemitones: semitones,
                vibrato: vibrato
            )
        )
    }

    private static func overblow(_ hole: Hole, _ beats: Double) -> ScoreEvent {
        .note(ScoreNote(hole: hole, breath: .blow, beats: beats, isOverbent: true))
    }
}
