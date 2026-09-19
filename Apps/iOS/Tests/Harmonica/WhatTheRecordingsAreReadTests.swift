import XCTest
@testable import MobileHarmonica

final class WhatTheRecordingsAreReadTests: XCTestCase {
    private let framesPerSecond = 44100.0

    // MARK: - Tests

    func test_recording_whenItsNameEndsInAPitch_soundsAnOctaveAboveTheLabel() throws {
        let hertz = try RecordedHarmonica.rootHertz(of: "hrmnca novbA2")

        XCTAssertEqual(hertz, 220, accuracy: 0.01, "the library labels an octave below concert pitch, so A2 is A3")
    }

    func test_recording_whenItsNameCarriesASharp_readsTheSharp() throws {
        XCTAssertEqual(RecordedHarmonica.midiNumber(of: "hrmnca novbC#3"), 49)
        XCTAssertEqual(try RecordedHarmonica.rootHertz(of: "hrmnca novbC#3"), 277.18, accuracy: 0.01)
    }

    func test_recording_whenItsNameEndsInNoPitch_isRefused() {
        XCTAssertNil(RecordedHarmonica.midiNumber(of: "hrmnca novb"))
        XCTAssertThrowsError(try RecordedHarmonica.rootHertz(of: "hrmnca novb"))
    }

    func test_loop_whenTheRecordingIsLongEnough_isSecondsOneToFour() throws {
        let loop = try loopBounds(withinSeconds: 11)

        XCTAssertEqual(loop, 44100..<176400)
    }

    func test_loop_whenTheRecordingRunsOutEarly_endsWhereTheFramesDo() throws {
        let loop = try loopBounds(withinSeconds: 2.5)

        XCTAssertEqual(loop, 44100..<110250)
    }

    func test_loop_whenTheRecordingIsTooShortToHoldOne_namesItself() {
        XCTAssertThrowsError(try loopBounds(withinSeconds: 1.1, named: "cut short")) { failure in
            guard case RecordedHarmonicaError.tooShortToLoop(let name, _) = failure else {
                return XCTFail("a recording that cannot be looped says which one it was")
            }

            XCTAssertEqual(name, "cut short")
        }
    }

    func test_loop_whenItWraps_arrivesFromWhereItLeftOff() throws {
        let loop = try loopBounds(withinSeconds: 4)
        let played = RecordedHarmonica.withASmoothedLoop(
            recordedTone(seconds: 4),
            loop: loop,
            framesPerSecond: framesPerSecond
        )

        let wrap = abs(played[loop.lowerBound] - played[loop.upperBound - 1])
        let ordinary = abs(played[loop.lowerBound] - played[loop.lowerBound - 1])
        XCTAssertLessThanOrEqual(wrap, ordinary * 1.001, "the wrap is no bigger a step than any other frame")
    }

    func test_loop_whenTheRecordingCannotSpareACrossfade_isLeftAlone() {
        let recorded = recordedTone(seconds: 0.01)

        let played = RecordedHarmonica.withASmoothedLoop(recorded, loop: 1..<100, framesPerSecond: framesPerSecond)

        XCTAssertEqual(played, recorded)
    }

    // MARK: - Helpers

    private func loopBounds(withinSeconds seconds: Double, named name: String = "test") throws -> Range<Int> {
        try RecordedHarmonica.loopBounds(
            framesPerSecond: framesPerSecond,
            within: Int(seconds * framesPerSecond),
            named: name
        )
    }

    private func recordedTone(seconds: Double) -> [Float] {
        (0..<Int(seconds * framesPerSecond)).map { frame in
            let at = Double(frame) / framesPerSecond
            return Float(sin(2 * Double.pi * 220 * at) * exp(-at / 8))
        }
    }
}
