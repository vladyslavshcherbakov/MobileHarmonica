extension ScoreEvent {
    static func blow(_ hole: Hole, _ beats: Double, vibrato: Double = 0, slideFrom: Hole? = nil) -> ScoreEvent {
        blow([hole], beats, vibrato: vibrato, slideFrom: slideFrom)
    }

    static func blow(
        _ holes: [Hole],
        _ beats: Double,
        vibrato: Double = 0,
        slideFrom: Hole? = nil
    ) -> ScoreEvent {
        .note(
            ScoreNote(
                holes: holes,
                breath: .blow,
                beats: beats,
                vibrato: vibrato,
                slideFrom: slideFrom
            )
        )
    }

    static func draw(
        _ hole: Hole,
        _ beats: Double,
        bentBy semitones: Double = 0,
        releasingTo released: Double? = nil,
        vibrato: Double = 0,
        slideFrom: Hole? = nil,
        shakenWith shaken: Hole? = nil
    ) -> ScoreEvent {
        .note(
            ScoreNote(
                holes: [hole],
                breath: .draw,
                beats: beats,
                bentBySemitones: semitones,
                vibrato: vibrato,
                slideFrom: slideFrom,
                shakenWith: shaken,
                bendEndsAtSemitones: released
            )
        )
    }

    static func draw(
        _ holes: [Hole],
        _ beats: Double,
        vibrato: Double = 0,
        slideFrom: Hole? = nil
    ) -> ScoreEvent {
        .note(
            ScoreNote(
                holes: holes,
                breath: .draw,
                beats: beats,
                vibrato: vibrato,
                slideFrom: slideFrom
            )
        )
    }

    static func overblow(_ hole: Hole, _ beats: Double) -> ScoreEvent {
        .note(ScoreNote(holes: [hole], breath: .blow, beats: beats, isOverbent: true))
    }
}
