import XCTest
@testable import MobileHarmonica

final class WhatTheShapingZoneChangesTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_shapingZone_whenTheFingerGoesBelowTheMiddle_sendsTheNewBendAndVibrato() {
        let harmonica = harmonica()

        _ = harmonica.shapeTone(PitchShaping(clamping: -0.25), vibrato: VibratoDepth(clamping: 0.75))

        XCTAssertEqual(engine.bends.last?.fraction, 0.25)
        XCTAssertEqual(engine.overbends.last?.fraction, 0)
        XCTAssertEqual(engine.vibratos.last?.fraction, 0.75)
    }

    func test_shapingZone_whenTheFingerIsJustAboveTheMiddle_leavesThePitchAlone() {
        let harmonica = harmonica()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.4), vibrato: .off)

        XCTAssertEqual(engine.overbends.last?.fraction, 0)
    }

    func test_shapingZone_whenTheFingerPassesTheOverbendThreshold_jumpsAllTheWayToIt() {
        let harmonica = harmonica()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.6), vibrato: .off)

        XCTAssertEqual(engine.bends.last?.fraction, 0)
        XCTAssertEqual(engine.overbends.last?.fraction, 1)
    }

    func test_shapingZone_whenTheFingerStaysStill_sendsNothingTwice() {
        let harmonica = harmonica()
        _ = harmonica.shapeTone(PitchShaping(clamping: -0.5), vibrato: VibratoDepth(clamping: 0.5))

        _ = harmonica.shapeTone(PitchShaping(clamping: -0.5), vibrato: VibratoDepth(clamping: 0.5))

        XCTAssertEqual(engine.bends.count, 1)
    }

    func test_harmonica_whenAFingerIsOnHoleThreeBelowTheLine_soundsTheDrawReed() {
        let harmonica = harmonica()

        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.3)])

        XCTAssertEqual(engine.soundedTones.last?.count, 1)
        XCTAssertEqual(engine.soundedTones.last?.first?.bendableSemitones, 3)
    }

    func test_harmonica_whenTheTopmostFingerIsAboveTheLine_blowsEveryHole() {
        let harmonica = harmonica()

        _ = harmonica.play(at: [
            PositionOnHarmonica(fractionFromLeftEdge: 0.05, fractionAboveCentreLine: 0.2),
            PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.4)
        ])

        XCTAssertEqual(engine.soundedTones.last?.map(\.bendableSemitones), [0, 0])
    }

    func test_harmonica_whenTheTopmostFingerHasSlidOffTheStrip_leavesTheBreathToTheNext() {
        let harmonica = harmonica()

        _ = harmonica.play(at: [
            PositionOnHarmonica(fractionFromLeftEdge: 1.4, fractionAboveCentreLine: 0.4),
            PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.3)
        ])

        XCTAssertEqual(engine.soundedTones.last?.count, 1)
        XCTAssertEqual(engine.soundedTones.last?.first?.bendableSemitones, 3)
    }

    // MARK: - Helpers

    private func harmonica() -> PlayHarmonica {
        PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
    }
}
