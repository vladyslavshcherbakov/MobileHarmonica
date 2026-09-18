import XCTest
@testable import MobileHarmonica

final class WhatAScorePlaysTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_score_whenItNamesAHole_soundsThatHolesReed() async {
        await play([.note(ScoreNote(holes: [.four], breath: .blow, beats: 1))])

        XCTAssertEqual(engine.hertzOfTheFirstTone, 523.25, accuracy: 0.5, "hole 4 blows C5")
    }

    func test_score_whenANoteIsBentBySemitones_bendsThatFarIntoTheReedsRange() async {
        await play([.note(ScoreNote(holes: [.three], breath: .draw, beats: 1, bentBySemitones: 1))])

        XCTAssertTrue(
            engine.bends.contains { $0.fraction == 0.33 },
            "a semitone of the three the hole 3 draw reed bends"
        )
    }

    func test_score_whenANoteIsOverbent_soundsTheOverblow() async {
        await play([.note(ScoreNote(holes: [.three], breath: .blow, beats: 1, isOverbent: true))])

        XCTAssertEqual(engine.hertzOfTheFirstTone, 523.25, accuracy: 0.5, "hole 3 overblown is C5")
    }

    func test_score_whenARestComes_soundsNothingForItsLength() async {
        await play([
            .note(ScoreNote(holes: [.four], breath: .draw, beats: 1)),
            .rest(beats: 1),
            .note(ScoreNote(holes: [.four], breath: .draw, beats: 1))
        ])

        XCTAssertEqual(engine.soundedTones.count, 2, "the rest between the two notes adds nothing")
        XCTAssertGreaterThan(engine.silencings, 1, "each note ends silent")
    }

    func test_score_whenItEnds_leavesNothingSounding() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1))])

        XCTAssertEqual(engine.soundedTones.last?.count, 1)
        XCTAssertGreaterThan(engine.silencings, 0)
    }

    func test_score_whenAnEventNamesSeveralHoles_soundsThemAsAChord() async {
        await play([.note(ScoreNote(holes: [.one, .two, .three], breath: .draw, beats: 1))])

        XCTAssertEqual(engine.soundedTones.first?.count, 3, "holes 1 to 3 drawn are D4 G4 B4")
    }

    func test_score_whenThePlayingStyleTakesOneFinger_stillSoundsEveryHoleTheScoreNames() async {
        let harmonica = PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
        _ = harmonica.changeStyle(to: .oneFingerSeveralNotes)

        await play([.note(ScoreNote(holes: [.one, .two, .three], breath: .draw, beats: 1))], on: harmonica)

        XCTAssertEqual(engine.soundedTones.first?.count, 3, "a score names holes, so nothing reinterprets them")
    }

    func test_score_whenItIsPlayedInSecondPosition_callsForTheHarmonicaAFifthBelow() async {
        let blues = Score(name: "test", key: .g, position: .second, beatsPerMinute: 6000, events: [])

        let played = await play(blues)

        XCTAssertEqual(played.first?.key, .c, "a blues in G is played on a harmonica in C")
    }

    func test_score_whenItIsPlayedInFirstPosition_callsForTheHarmonicaItIsWrittenIn() async {
        let tune = Score(name: "test", key: .d, position: .first, beatsPerMinute: 6000, events: [])

        let played = await play(tune)

        XCTAssertEqual(played.first?.key, .d)
    }

    func test_score_whenANoteSlidesUpFromAnotherHole_soundsTheHolesOnTheWay() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1, slideFrom: .one))])

        XCTAssertEqual(engine.soundedTones.count, 4, "holes 1, 2 and 3 pass before hole 4 arrives")
        XCTAssertEqual(engine.hertzOfTheLastTone, 587.33, accuracy: 0.5, "hole 4 draws D5")
    }

    func test_score_whenANoteSlidesDownFromAnotherHole_passesTheHolesInReverse() async {
        await play([.note(ScoreNote(holes: [.one], breath: .draw, beats: 1, slideFrom: .three))])

        XCTAssertEqual(engine.soundedTones.count, 3)
        XCTAssertEqual(engine.hertzOfTheFirstTone, 493.88, accuracy: 0.5, "hole 3 draws B4 first")
    }

    func test_score_whenTheSlideStartsWhereTheNoteIs_soundsOnlyTheNote() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1, slideFrom: .four))])

        XCTAssertEqual(engine.soundedTones.count, 1)
    }

    func test_score_whenANoteIsShaken_rocksBetweenTheTwoHoles() async {
        await play(
            [.note(ScoreNote(holes: [.four], breath: .draw, beats: 1, shakenWith: .five))],
            atBeatsPerMinute: 240
        )

        let hertz = engine.soundedTones.compactMap { $0.first?.pitch.converted(to: .hertz).value }
        XCTAssertGreaterThan(hertz.count, 2, "a shaken note re-sounds on every swing")
        XCTAssertEqual(hertz.first ?? 0, 587.33, accuracy: 0.5, "hole 4 draws D5")
        XCTAssertEqual(hertz.dropFirst().first ?? 0, 698.46, accuracy: 0.5, "hole 5 draws F5")
    }

    func test_score_whenABendIsReleased_walksTheBendBackToNothing() async {
        await play(
            [.note(ScoreNote(holes: [.three], breath: .draw, beats: 1, bentBySemitones: 2, bendEndsAtSemitones: 0))],
            atBeatsPerMinute: 240
        )

        let bends = engine.bends.map(\.fraction)
        XCTAssertEqual(bends.first ?? 0, 0.67, accuracy: 0.02, "two of the three semitones hole 3 draw bends")
        XCTAssertEqual(bends.last ?? 1, 0, accuracy: 0.02)
    }

    func test_score_whenANoteIsPlain_soundsItOnce() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1))])

        XCTAssertEqual(engine.soundedTones.count, 1, "no expression means no stepping")
    }

    // MARK: - Helpers

    @discardableResult
    private func play(
        _ events: [ScoreEvent],
        on harmonica: PlayHarmonica? = nil,
        atBeatsPerMinute tempo: Double = 6000
    ) async -> [Harmonica] {
        await play(
            Score(name: "test", key: .c, position: .first, beatsPerMinute: tempo, events: events),
            on: harmonica
        )
    }

    @discardableResult
    private func play(_ score: Score, on existing: PlayHarmonica? = nil) async -> [Harmonica] {
        let harmonica = existing ?? PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
        let player = PlayScore(tuning: RichterTuning(), harmonica: harmonica, log: SilentLog())

        var played: [Harmonica] = []
        for await state in player.play(score) {
            played.append(state)
        }
        return played
    }
}
