import HarmonicaCoreTestSupport
import XCTest
@testable import HarmonicaCore

final class WhatEachPlayingStyleCoversTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_oneNotePerFinger_whenTheContactIsWide_soundsOneHolePerFinger() {
        let harmonica = playing(.severalFingersOneNote)

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.06, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.three])
    }

    func test_oneNotePerFinger_whenTwoFingersAreDown_soundsAHolePerFinger() {
        let harmonica = playing(.severalFingersOneNote)

        let sounding = harmonica.play(at: [
            contact(at: 0.05, covering: 0.06, above: 0.2),
            contact(at: 0.45, covering: 0.06, above: 0.2)
        ]).soundingHoles

        XCTAssertEqual(sounding, [.one, .five])
    }

    func test_severalNotesPerFinger_whenTheContactIsNarrowerThanAHole_soundsOneHole() {
        let harmonica = playing(.severalFingersSeveralNotes)

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.02, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.three])
    }

    func test_severalNotesPerFinger_whenTheContactCrossesAHoleBoundary_soundsBothHoles() {
        let harmonica = playing(.severalFingersSeveralNotes)

        let sounding = harmonica.play(at: [contact(at: 0.29, covering: 0.02, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.three, .four])
    }

    func test_severalNotesPerFinger_whenASecondFingerIsDown_soundsWhatBothFingersCover() {
        let harmonica = playing(.severalFingersSeveralNotes)

        let sounding = harmonica.play(at: [
            contact(at: 0.05, covering: 0.02, above: 0.2),
            contact(at: 0.45, covering: 0.06, above: -0.3)
        ]).soundingHoles

        XCTAssertEqual(sounding, [.one, .four, .five, .six], "one finger brings a hole, the other brings three")
    }

    func test_oneFinger_whenTheContactSpansThreeHoles_soundsAllThree() {
        let harmonica = playing(.oneFingerSeveralNotes)

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.06, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.two, .three, .four])
    }

    func test_oneFinger_whenASecondFingerIsOnTheStrip_soundsOnlyTheTopmost() {
        let harmonica = playing(.oneFingerSeveralNotes)

        let sounding = harmonica.play(at: [
            contact(at: 0.05, covering: 0.02, above: 0.2),
            contact(at: 0.45, covering: 0.02, above: -0.3)
        ]).soundingHoles

        XCTAssertEqual(sounding, [.one])
    }

    func test_oneFinger_whenTheCentreIsBelowTheLine_drawsEveryCoveredHole() {
        let harmonica = playing(.oneFingerSeveralNotes)

        _ = harmonica.play(at: [contact(at: 0.29, covering: 0.02, above: -0.3)])

        XCTAssertEqual(
            engine.soundedTones.last?.map { $0.pitch.converted(to: .hertz).value.rounded() },
            [494, 587],
            "holes 3 and 4 draw B4 and D5, where blowing them would be G4 and C5"
        )
    }

    func test_playingStyle_whenSwitchedWhileAHoleSounds_silencesIt() {
        let harmonica = playing(.severalFingersSeveralNotes)
        _ = harmonica.play(at: [contact(at: 0.25, covering: 0.02, above: 0.2)])

        let sounding = harmonica.changeStyle(to: .severalFingersOneNote).soundingHoles

        XCTAssertEqual(sounding, [])
        XCTAssertEqual(engine.silencings, 1)
    }

    // MARK: - Helpers

    private func playing(_ style: PlayingStyle) -> PlayHarmonica {
        let harmonica = PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
        _ = harmonica.changeStyle(to: style)
        return harmonica
    }

    private func contact(at fromLeftEdge: Double, covering eitherSide: Double, above centreLine: Double) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: fromLeftEdge,
            fractionAboveCentreLine: centreLine,
            fractionCoveredEitherSide: eitherSide
        )
    }
}
