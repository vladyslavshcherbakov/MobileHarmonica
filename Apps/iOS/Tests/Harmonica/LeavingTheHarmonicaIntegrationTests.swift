import XCTest
@testable import MobileHarmonica

@MainActor
final class LeavingTheHarmonicaIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_harmonica_whenTheAppGoesToTheBackgroundWhileANoteSounds_ringsTheReedsDown() async {
        let screen = await environment.harmonicaScreen()
        screen.touchStrip(at: 0.35, above: 0.2)

        screen.sendTheAppToTheBackground()

        XCTAssertEqual(environment.engine.releases.last, .ringsDown)
        XCTAssertNil(screen.hole(4)?.lit)
    }

    func test_harmonica_whenTheSettingsOpenWhileANoteSounds_ringsTheReedsDown() async {
        let screen = await environment.harmonicaScreen()
        screen.touchStrip(at: 0.35, above: 0.2)

        screen.leave()

        XCTAssertEqual(environment.engine.releases.last, .ringsDown)
        XCTAssertNil(screen.hole(4)?.lit)
    }
}
