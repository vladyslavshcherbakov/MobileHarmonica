import XCTest
@testable import MobileHarmonica

final class WhatTheShapingZoneChangesTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_shapingZone_whenTheFingerMoves_sendsTheNewBendAndVibrato() {
        let harmonica = harmonica()

        harmonica.shapeTone(bend: BendDepth(clamping: 0.25), vibrato: VibratoDepth(clamping: 0.75))

        XCTAssertEqual(engine.bends.last?.fraction, 0.25)
        XCTAssertEqual(engine.vibratos.last?.fraction, 0.75)
    }

    func test_shapingZone_whenTheFingerStaysStill_sendsNothingTwice() {
        let harmonica = harmonica()
        harmonica.shapeTone(bend: BendDepth(clamping: 0.5), vibrato: VibratoDepth(clamping: 0.5))

        harmonica.shapeTone(bend: BendDepth(clamping: 0.5), vibrato: VibratoDepth(clamping: 0.5))

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

    // MARK: - Helpers

    private func harmonica() -> PlayHarmonica {
        PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
    }
}
