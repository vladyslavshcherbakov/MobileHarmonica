import HarmonicaCoreTestSupport
import XCTest
@testable import HarmonicaCore

@MainActor
final class ScorePlaybackIntegrationTests: XCTestCase {
    private let environment = InstrumentEnvironment()

    // MARK: - Tests

    func test_score_whenItNamesAHole_soundsThatHolesReed() async {
        await play([.note(ScoreNote(holes: [.four], breath: .blow, beats: 1))])

        XCTAssertEqual(environment.engine.hertzOfTheFirstTone, 523.25, accuracy: 0.5, "hole 4 blows C5")
    }

    func test_score_whenANoteIsBentBySemitones_bendsThatFarIntoTheReedsRange() async {
        await play([.note(ScoreNote(holes: [.three], breath: .draw, beats: 1, bentBySemitones: 1))])

        XCTAssertTrue(
            environment.engine.bends.contains { $0.fraction == 0.33 },
            "a semitone of the three the hole 3 draw reed bends"
        )
    }

    func test_score_whenANoteNamesItsBreathIntensity_isBlownThatHard() async {
        await play([.note(ScoreNote(holes: [.four], breath: .blow, beats: 1, breathIntensity: 0.5))])

        XCTAssertEqual(environment.engine.intensities, [BreathIntensity(gain: 0.5)])
    }

    func test_score_whenANoteNamesNoBreathIntensity_isBlownAtFullPressure() async {
        await play([.note(ScoreNote(holes: [.four], breath: .blow, beats: 1))])

        XCTAssertEqual(environment.engine.intensities, [.full])
    }

    func test_score_whenANoteIsOverbent_soundsTheOverblow() async {
        await play([.note(ScoreNote(holes: [.three], breath: .blow, beats: 1, isOverbent: true))])

        XCTAssertEqual(environment.engine.hertzOfTheFirstTone, 523.25, accuracy: 0.5, "hole 3 overblown is C5")
    }

    func test_score_whenARestComes_soundsNothingForItsLength() async {
        await play([
            .note(ScoreNote(holes: [.four], breath: .draw, beats: 1)),
            .rest(beats: 1),
            .note(ScoreNote(holes: [.four], breath: .draw, beats: 1))
        ])

        XCTAssertEqual(environment.engine.soundedTones.count, 2, "the rest between the two notes adds nothing")
        XCTAssertEqual(environment.engine.releases, [.damped, .damped], "each note is tongued off")
    }

    func test_score_whenItEnds_leavesNothingSounding() async {
        let states = await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1))])

        XCTAssertEqual(states.last?.sounding, [:])
    }

    func test_score_whenAnEventNamesSeveralHoles_soundsThemAsAChord() async {
        await play([.note(ScoreNote(holes: [.one, .two, .three], breath: .draw, beats: 1))])

        XCTAssertEqual(environment.engine.soundedTones.first?.count, 3, "holes 1 to 3 drawn are D4 G4 B4")
    }

    func test_score_whenThePlayingStyleTakesOneFinger_stillSoundsEveryHoleTheScoreNames() async {
        _ = environment.playHarmonica.changeStyle(to: .oneFingerSeveralNotes)

        await play([.note(ScoreNote(holes: [.one, .two, .three], breath: .draw, beats: 1))])

        XCTAssertEqual(environment.engine.soundedTones.first?.count, 3, "a score names holes, so nothing reinterprets them")
    }

    func test_score_whenItIsPlayedInSecondPosition_callsForTheHarmonicaAFifthBelow() async {
        let blues = Score(name: "test", key: .g, position: .second, beatsPerMinute: 6000, events: [])

        let states = await play(blues)

        XCTAssertEqual(states.first?.key, .c, "a blues in G is played on a harmonica in C")
    }

    func test_score_whenItIsPlayedInFirstPosition_callsForTheHarmonicaItIsWrittenIn() async {
        let tune = Score(name: "test", key: .d, position: .first, beatsPerMinute: 6000, events: [])

        let states = await play(tune)

        XCTAssertEqual(states.first?.key, .d)
    }

    func test_score_whenANoteSlidesUpFromAnotherHole_soundsTheHolesOnTheWay() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1, slideFrom: .one))])

        XCTAssertEqual(environment.engine.soundedTones.count, 4, "holes 1, 2 and 3 pass before hole 4 arrives")
        XCTAssertEqual(environment.engine.hertzOfTheLastTone, 587.33, accuracy: 0.5, "hole 4 draws D5")
    }

    func test_score_whenANoteSlidesDownFromAnotherHole_passesTheHolesInReverse() async {
        await play([.note(ScoreNote(holes: [.one], breath: .draw, beats: 1, slideFrom: .three))])

        XCTAssertEqual(environment.engine.soundedTones.count, 3)
        XCTAssertEqual(environment.engine.hertzOfTheFirstTone, 493.88, accuracy: 0.5, "hole 3 draws B4 first")
    }

    func test_score_whenTheSlideStartsWhereTheNoteIs_soundsOnlyTheNote() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1, slideFrom: .four))])

        XCTAssertEqual(environment.engine.soundedTones.count, 1)
    }

    func test_score_whenANoteIsShaken_rocksBetweenTheTwoHoles() async {
        await play(
            [.note(ScoreNote(holes: [.four], breath: .draw, beats: 1, shakenWith: .five))],
            atBeatsPerMinute: 240
        )

        let hertz = environment.engine.soundedTones.compactMap { $0.first?.pitch.converted(to: .hertz).value }
        XCTAssertGreaterThan(hertz.count, 2, "a shaken note re-sounds on every swing")
        XCTAssertEqual(hertz.first ?? 0, 587.33, accuracy: 0.5, "hole 4 draws D5")
        XCTAssertEqual(hertz.dropFirst().first ?? 0, 698.46, accuracy: 0.5, "hole 5 draws F5")
    }

    func test_score_whenABendIsReleased_walksTheBendBackToNothing() async {
        await play(
            [.note(ScoreNote(holes: [.three], breath: .draw, beats: 1, bentBySemitones: 2, bendEndsAtSemitones: 0))],
            atBeatsPerMinute: 240
        )

        let bends = environment.engine.bends.map(\.fraction)
        XCTAssertEqual(bends.first ?? 0, 0.67, accuracy: 0.02, "two of the three semitones hole 3 draw bends")
        XCTAssertEqual(bends.last ?? 1, 0, accuracy: 0.02)
    }

    func test_score_whenANoteIsPlain_soundsItOnce() async {
        await play([.note(ScoreNote(holes: [.four], breath: .draw, beats: 1))])

        XCTAssertEqual(environment.engine.soundedTones.count, 1, "no expression means no stepping")
    }

    func test_score_whenItIsStoppedPartWay_leavesTheFingersNoteSounding() async {
        let score = Score(
            name: "test",
            key: .c,
            position: .first,
            beatsPerMinute: 60,
            events: [
                .note(ScoreNote(holes: [.two], breath: .draw, beats: 1)),
                .note(ScoreNote(holes: [.three], breath: .draw, beats: 1))
            ]
        )
        let performance = Task { await environment.playScore.play(score) { _ in } }
        _ = await waitUntil { !self.environment.engine.soundedTones.isEmpty }
        performance.cancel()

        _ = environment.playHarmonica.play([.four], breathing: .blow)

        let scoreStopped = await waitUntil { self.environment.log.lines.contains("score stopped early") }
        XCTAssertTrue(scoreStopped)
        XCTAssertEqual(environment.engine.releases, [], "a stopped score does not damp what the finger sounds")
        XCTAssertEqual(environment.engine.hertzOfTheLastTone, 523.25, accuracy: 0.5, "hole 4 blown is still what is heard")
    }

    // MARK: - Helpers

    @discardableResult
    private func play(_ events: [ScoreEvent], atBeatsPerMinute tempo: Double = 6000) async -> [Harmonica] {
        await play(Score(name: "test", key: .c, position: .first, beatsPerMinute: tempo, events: events))
    }

    @discardableResult
    private func play(_ score: Score) async -> [Harmonica] {
        var states: [Harmonica] = []
        await environment.playScore.play(score) { states.append($0) }
        return states
    }
}
