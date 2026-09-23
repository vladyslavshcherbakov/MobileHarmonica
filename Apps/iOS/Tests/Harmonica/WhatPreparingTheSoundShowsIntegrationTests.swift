import XCTest
@testable import MobileHarmonica

@MainActor
final class WhatPreparingTheSoundShowsIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_harmonicaScreen_whenTheEngineIsReady_showsTheHarmonica() async {
        let screen = await environment.harmonicaScreen()

        XCTAssertEqual(screen.playable?.holes.count, 10)
    }

    func test_harmonicaScreen_whenTheEngineCannotStart_saysSoundIsUnavailable() async {
        environment.engine.preparationFailure = .outputRefused

        let screen = await environment.harmonicaScreen()

        XCTAssertNotNil(screen.unavailableText)
        XCTAssertNil(screen.playable)
    }

    func test_harmonicaScreen_whenTheSoundIsUnavailable_ignoresTheStrip() async {
        environment.engine.preparationFailure = .noRecordings
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.35, above: 0.2)

        XCTAssertEqual(environment.engine.soundedTones, [])
    }
}
