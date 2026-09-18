import XCTest
@testable import MobileHarmonica

final class WhatTheShapingZoneChangesTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_shapingZone_whenTheFingerGoesBelowTheMiddle_sendsTheNewBendAndVibrato() {
        let harmonica = harmonica()

        _ = harmonica.shapeTone(PitchShaping(clamping: -0.25), vibrato: VibratoDepth(clamping: 0.75))

        XCTAssertEqual(engine.bends.last?.fraction, 0.25)
        XCTAssertEqual(engine.vibratos.last?.fraction, 0.75)
    }

    func test_shapingZone_whenTheFingerIsJustAboveTheMiddle_leavesTheReedSounding() {
        let harmonica = blowingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.4), vibrato: .off)

        XCTAssertEqual(engine.soundedTones.count, 1)
    }

    func test_shapingZone_whenTheFingerPassesTheOverbendThreshold_soundsTheOverblowInstead() {
        let harmonica = blowingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.6), vibrato: .off)

        XCTAssertEqual(hertzOfTheLastTone(), 523.25, accuracy: 0.5, "G4 overblown is C5")
        XCTAssertEqual(engine.soundedTones.last?.first?.bendableSemitones, 0)
    }

    func test_shapingZone_whenTheOverblowStarts_crossfadesAsANewReedRatherThanASlide() {
        let harmonica = blowingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.6), vibrato: .off)

        XCTAssertEqual(engine.toneChanges, [.slide, .newReed])
    }

    func test_shapingZone_whenTheFingerLeavesTheOverbend_soundsThePlainReedAgain() {
        let harmonica = blowingHoleThree()
        _ = harmonica.shapeTone(PitchShaping(clamping: 0.6), vibrato: .off)

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.1), vibrato: .off)

        XCTAssertEqual(hertzOfTheLastTone(), 392.00, accuracy: 0.5, "hole 3 blows G4")
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

    private func blowingHoleThree() -> PlayHarmonica {
        let harmonica = harmonica()
        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: 0.2)])
        return harmonica
    }

    private func hertzOfTheLastTone() -> Double {
        engine.soundedTones.last?.first?.pitch.converted(to: .hertz).value ?? 0
    }
}
