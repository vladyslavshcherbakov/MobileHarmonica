import XCTest
@testable import MobileHarmonica

final class WhatAScorePlaysTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_score_whenItNamesAHole_soundsThatHolesReed() async {
        await play([.note(ScoreNote(hole: .four, breath: .blow, beats: 1))])

        XCTAssertEqual(hertzOfTheFirstTone(), 523.25, accuracy: 0.5, "hole 4 blows C5")
    }

    func test_score_whenANoteIsBentBySemitones_bendsThatFarIntoTheReedsRange() async {
        await play([.note(ScoreNote(hole: .three, breath: .draw, beats: 1, bentBySemitones: 1))])

        XCTAssertTrue(
            engine.bends.contains { $0.fraction == 0.33 },
            "a semitone of the three the hole 3 draw reed bends"
        )
    }

    func test_score_whenANoteIsOverbent_soundsTheOverblow() async {
        await play([.note(ScoreNote(hole: .three, breath: .blow, beats: 1, isOverbent: true))])

        XCTAssertEqual(hertzOfTheFirstTone(), 523.25, accuracy: 0.5, "hole 3 overblown is C5")
    }

    func test_score_whenARestComes_silencesTheHarmonica() async {
        await play([.rest(beats: 1)])

        XCTAssertGreaterThan(engine.silencings, 0)
    }

    func test_score_whenItEnds_leavesNothingSounding() async {
        await play([.note(ScoreNote(hole: .four, breath: .draw, beats: 1))])

        XCTAssertEqual(engine.soundedTones.last?.count, 1)
        XCTAssertGreaterThan(engine.silencings, 0)
    }

    // MARK: - Helpers

    private func play(_ events: [ScoreEvent]) async {
        let harmonica = PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
        let player = PlayScore(tuning: RichterTuning(), harmonica: harmonica, log: SilentLog())

        for await _ in player.play(Score(key: .c, beatsPerMinute: 6000, events: events)) {}
    }

    private func hertzOfTheFirstTone() -> Double {
        engine.soundedTones.first?.first?.pitch.converted(to: .hertz).value ?? 0
    }
}
