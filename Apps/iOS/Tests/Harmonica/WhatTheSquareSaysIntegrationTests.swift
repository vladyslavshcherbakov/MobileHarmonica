import XCTest
@testable import MobileHarmonica

@MainActor
final class WhatTheSquareSaysIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_square_whenABlowReedSounds_callsTheUpperAxisTheOverblow() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.25, above: 0.2)

        XCTAssertEqual(screen.playable?.toneShaping.overbendLabel, "overblow ↑", "hole 3 blown overblows")
    }

    func test_square_whenADrawReedSounds_callsTheUpperAxisTheOverdraw() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.85, above: -0.3)

        XCTAssertEqual(screen.playable?.toneShaping.overbendLabel, "overdraw ↑", "hole 9 drawn overdraws")
    }

    func test_square_whenNothingSounds_namesNeitherTechnique() async {
        let screen = await environment.harmonicaScreen()

        screen.liftFromTheStrip()

        XCTAssertEqual(screen.playable?.toneShaping.overbendLabel, "overbend ↑")
    }

    func test_square_whenTheSoundingReedOverbendsButCannotBend_dimsTheBendAlone() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.25, above: 0.2)

        XCTAssertEqual(screen.playable?.toneShaping.isBendAvailable, false)
        XCTAssertEqual(screen.playable?.toneShaping.isOverbendAvailable, true)
    }

    func test_square_whenTheSoundingReedBendsButCannotOverbend_dimsTheOverbendAlone() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.25, above: -0.3)

        XCTAssertEqual(screen.playable?.toneShaping.isBendAvailable, true, "hole 3 drawn bends three semitones")
        XCTAssertEqual(screen.playable?.toneShaping.isOverbendAvailable, false)
    }
}
