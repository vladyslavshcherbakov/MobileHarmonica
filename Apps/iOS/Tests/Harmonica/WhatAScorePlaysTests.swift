import XCTest
@testable import MobileHarmonica

final class WhatAScorePlaysTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_score_whenItNamesAHole_soundsThatHolesReed() async {
        await play([.note(ScoreNote(holes: [.four], breath: .blow, beats: 1))])

        XCTAssertEqual(hertzOfTheFirstTone(), 523.25, accuracy: 0.5, "hole 4 blows C5")
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

        XCTAssertEqual(hertzOfTheFirstTone(), 523.25, accuracy: 0.5, "hole 3 overblown is C5")
    }

    func test_score_whenARestComes_silencesTheHarmonica() async {
        await play([.rest(beats: 1)])

        XCTAssertGreaterThan(engine.silencings, 0)
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

    func test_score_whenItIsPlayedInSecondPosition_callsForTheHarmonicaAFifthBelow() async {
        let blues = Score(key: .g, position: .second, beatsPerMinute: 6000, events: [])

        let played = await play(blues)

        XCTAssertEqual(played.first?.key, .c, "a blues in G is played on a harmonica in C")
    }

    func test_score_whenItIsPlayedInFirstPosition_callsForTheHarmonicaItIsWrittenIn() async {
        let tune = Score(key: .d, position: .first, beatsPerMinute: 6000, events: [])

        let played = await play(tune)

        XCTAssertEqual(played.first?.key, .d)
    }

    func test_score_whenANoteSlidesUpFromAnotherHole_soundsTheHolesOnTheWay() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1, slideFrom: .one))])

        XCTAssertEqual(engine.soundedTones.count, 4, "holes 1, 2 and 3 pass before hole 4 arrives")
        XCTAssertEqual(hertzOfTheLastTone(), 587.33, accuracy: 0.5, "hole 4 draws D5")
    }

    func test_score_whenANoteSlidesDownFromAnotherHole_passesTheHolesInReverse() async {
        await play([.note(ScoreNote(holes: [.one], breath: .draw, beats: 1, slideFrom: .three))])

        XCTAssertEqual(engine.soundedTones.count, 3)
        XCTAssertEqual(hertzOfTheFirstTone(), 493.88, accuracy: 0.5, "hole 3 draws B4 first")
    }

    func test_score_whenTheSlideStartsWhereTheNoteIs_soundsOnlyTheNote() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1, slideFrom: .four))])

        XCTAssertEqual(engine.soundedTones.count, 1)
    }

    // MARK: - Helpers

    @discardableResult
    private func play(_ events: [ScoreEvent]) async -> [Harmonica] {
        await play(Score(key: .c, position: .first, beatsPerMinute: 6000, events: events))
    }

    @discardableResult
    private func play(_ score: Score) async -> [Harmonica] {
        let harmonica = PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
        let player = PlayScore(tuning: RichterTuning(), harmonica: harmonica, log: SilentLog())

        var played: [Harmonica] = []
        for await state in player.play(score) {
            played.append(state)
        }
        return played
    }

    private func hertzOfTheFirstTone() -> Double {
        engine.soundedTones.first?.first?.pitch.converted(to: .hertz).value ?? 0
    }
}
