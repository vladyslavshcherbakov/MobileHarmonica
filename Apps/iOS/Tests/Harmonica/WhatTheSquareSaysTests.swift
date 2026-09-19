import Foundation
import XCTest
@testable import MobileHarmonica
import HarmonicaCore
import HarmonicaCoreTestSupport

final class WhatTheSquareSaysTests: XCTestCase {
    private let engine = RecordingAudioEngine()
    private let presenter = HarmonicaPresenter(locale: Locale(identifier: "en_US_POSIX"), tunes: [])

    // MARK: - Tests

    func test_square_whenABlowReedSounds_callsTheUpperAxisTheOverblow() {
        let shaping = shaping(under: finger(at: 0.25, above: 0.2))

        XCTAssertEqual(shaping?.overbendLabel, "overblow ↑", "hole 3 blown overblows")
    }

    func test_square_whenADrawReedSounds_callsTheUpperAxisTheOverdraw() {
        let shaping = shaping(under: finger(at: 0.85, above: -0.3))

        XCTAssertEqual(shaping?.overbendLabel, "overdraw ↑", "hole 9 drawn overdraws")
    }

    func test_square_whenNothingSounds_namesNeitherTechnique() {
        let shaping = shaping(under: nil)

        XCTAssertEqual(shaping?.overbendLabel, "overbend ↑")
    }

    func test_square_whenTheSoundingReedOverbendsButCannotBend_dimsTheBendAlone() {
        let shaping = shaping(under: finger(at: 0.25, above: 0.2))

        XCTAssertEqual(shaping?.bendIsAvailable, false)
        XCTAssertEqual(shaping?.overbendIsAvailable, true)
    }

    func test_square_whenTheSoundingReedBendsButCannotOverbend_dimsTheOverbendAlone() {
        let shaping = shaping(under: finger(at: 0.25, above: -0.3))

        XCTAssertEqual(shaping?.bendIsAvailable, true, "hole 3 drawn bends three semitones")
        XCTAssertEqual(shaping?.overbendIsAvailable, false)
    }

    // MARK: - Helpers

    private func shaping(under finger: PositionOnHarmonica?) -> ToneShapingViewState? {
        let harmonica = PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
        let played = harmonica.play(at: finger.map { [$0] } ?? [])
        guard case .ready(let playable) = presenter.present(played, playingAScore: false) else { return nil }

        return playable.toneShaping
    }

    private func finger(at fromLeftEdge: Double, above centreLine: Double) -> PositionOnHarmonica {
        PositionOnHarmonica(fractionFromLeftEdge: fromLeftEdge, fractionAboveCentreLine: centreLine)
    }
}
