extension Score {
    static let demo = Score(key: .c, beatsPerMinute: 96, events: twelveBarBlues)

    private static let twelveBarBlues: [ScoreEvent] =
        chuggedBar + chuggedBar + openingRiff + heldTonic
        + subdominantStabs + subdominantAnswer + chuggedBar + upperFill
        + dominantChord + subdominantChord + tonicAnswer + turnaround

    private static let chuggedBar: [ScoreEvent] = chug + chug + chug + chug

    private static let chug: [ScoreEvent] = [
        draw([.one, .two], 0.667), blow([.one, .two], 0.333)
    ]

    private static let openingRiff: [ScoreEvent] = [
        draw(.two, 1), draw(.three, 1, bentBy: 1),
        blow(.four, 0.667), draw(.three, 0.333, bentBy: 1), draw(.two, 1)
    ]

    private static let heldTonic: [ScoreEvent] = [
        draw(.two, 3, vibrato: 0.8), .rest(beats: 1)
    ]

    private static let subdominantStabs: [ScoreEvent] = [
        blow([.one, .two, .three], 0.667), .rest(beats: 0.333),
        blow([.one, .two, .three], 0.667), .rest(beats: 0.333),
        blow(.four, 1), blow(.five, 1)
    ]

    private static let subdominantAnswer: [ScoreEvent] = [
        blow(.five, 0.667), draw(.four, 0.333), blow(.four, 1),
        blow([.one, .two, .three], 2)
    ]

    private static let upperFill: [ScoreEvent] = [
        blow(.six, 0.5), overblow(.six, 0.5), draw(.six, 0.5), blow(.six, 0.5),
        draw(.five, 1), draw(.four, 1)
    ]

    private static let dominantChord: [ScoreEvent] = [
        draw([.four, .five, .six], 2), draw(.four, 1), draw(.five, 1)
    ]

    private static let subdominantChord: [ScoreEvent] = [
        blow([.four, .five, .six], 2), blow(.four, 1), draw(.three, 1, bentBy: 1)
    ]

    private static let tonicAnswer: [ScoreEvent] = [
        draw(.two, 2, vibrato: 0.8), draw(.three, 1, bentBy: 1), blow(.four, 1)
    ]

    private static let turnaround: [ScoreEvent] = [
        draw(.three, 0.667, bentBy: 1), draw(.two, 0.333), draw(.one, 1),
        draw([.one, .two], 2)
    ]

    private static func blow(_ hole: Hole, _ beats: Double) -> ScoreEvent {
        blow([hole], beats)
    }

    private static func blow(_ holes: [Hole], _ beats: Double) -> ScoreEvent {
        .note(ScoreNote(holes: holes, breath: .blow, beats: beats))
    }

    private static func draw(
        _ hole: Hole,
        _ beats: Double,
        bentBy semitones: Double = 0,
        vibrato: Double = 0
    ) -> ScoreEvent {
        .note(
            ScoreNote(
                holes: [hole],
                breath: .draw,
                beats: beats,
                bentBySemitones: semitones,
                vibrato: vibrato
            )
        )
    }

    private static func draw(_ holes: [Hole], _ beats: Double) -> ScoreEvent {
        .note(ScoreNote(holes: holes, breath: .draw, beats: beats))
    }

    private static func overblow(_ hole: Hole, _ beats: Double) -> ScoreEvent {
        .note(ScoreNote(holes: [hole], breath: .blow, beats: beats, isOverbent: true))
    }
}
