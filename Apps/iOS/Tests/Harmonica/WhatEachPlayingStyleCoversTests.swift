import XCTest
@testable import MobileHarmonica

final class WhatEachPlayingStyleCoversTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_notes_whenTheContactIsWide_soundsOneHolePerFinger() {
        let harmonica = playing(.notes)

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.06, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.three])
    }

    func test_notes_whenTwoFingersAreDown_soundsAHolePerFinger() {
        let harmonica = playing(.notes)

        let sounding = harmonica.play(at: [
            contact(at: 0.05, covering: 0.06, above: 0.2),
            contact(at: 0.45, covering: 0.06, above: 0.2)
        ]).soundingHoles

        XCTAssertEqual(sounding, [.one, .five])
    }

    func test_mouth_whenTheContactIsNarrowerThanAHole_soundsOneHole() {
        let harmonica = playing(.mouth)

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.02, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.three])
    }

    func test_mouth_whenTheContactCrossesAHoleBoundary_soundsBothHoles() {
        let harmonica = playing(.mouth)

        let sounding = harmonica.play(at: [contact(at: 0.29, covering: 0.02, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.three, .four])
    }

    func test_mouth_whenASecondFingerIsDown_soundsWhatBothFingersCover() {
        let harmonica = playing(.mouth)

        let sounding = harmonica.play(at: [
            contact(at: 0.05, covering: 0.02, above: 0.2),
            contact(at: 0.45, covering: 0.06, above: -0.3)
        ]).soundingHoles

        XCTAssertEqual(sounding, [.one, .four, .five, .six], "one finger brings a hole, the other brings three")
    }

    func test_solo_whenTheContactSpansThreeHoles_soundsAllThree() {
        let harmonica = playing(.solo)

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.06, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.two, .three, .four])
    }

    func test_solo_whenASecondFingerIsOnTheStrip_soundsOnlyTheTopmost() {
        let harmonica = playing(.solo)

        let sounding = harmonica.play(at: [
            contact(at: 0.05, covering: 0.02, above: 0.2),
            contact(at: 0.45, covering: 0.02, above: -0.3)
        ]).soundingHoles

        XCTAssertEqual(sounding, [.one])
    }

    func test_solo_whenTheCentreIsBelowTheLine_drawsEveryCoveredHole() {
        let harmonica = playing(.solo)

        _ = harmonica.play(at: [contact(at: 0.29, covering: 0.02, above: -0.3)])

        XCTAssertEqual(engine.soundedTones.last?.map(\.bendableSemitones), [3, 1])
    }

    func test_playingStyle_whenSwitchedWhileAHoleSounds_silencesIt() {
        let harmonica = playing(.mouth)
        _ = harmonica.play(at: [contact(at: 0.25, covering: 0.02, above: 0.2)])

        let sounding = harmonica.changeStyle(to: .notes).soundingHoles

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
