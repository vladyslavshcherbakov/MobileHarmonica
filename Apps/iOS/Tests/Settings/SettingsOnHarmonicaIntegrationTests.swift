import ComposableArchitecture
import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class SettingsOnHarmonicaIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_harmonica_whenOneFingerIsChosenInTheSettings_soundsOnlyTheTopmostFingerOnReturn() async {
        let screen = await environment.harmonicaScreen()
        await screen.openTheSettings().chooseStyle(.oneFingerSeveralNotes)
        screen.comeBackFromTheSettings()

        screen.touchStrip(with: twoFingersWithHoleTwoOnTop)

        XCTAssertEqual(screen.hole(2)?.lit, .top)
        XCTAssertNil(screen.hole(8)?.lit, "hole 8 is under the lower finger")
    }

    func test_harmonica_whenLaunchedWithOneFingerChosen_soundsOnlyTheTopmostFinger() async {
        await environment.settingsScreen().chooseStyle(.oneFingerSeveralNotes)
        let screen = await environment.relaunched().harmonicaScreen()

        screen.touchStrip(with: twoFingersWithHoleTwoOnTop)

        XCTAssertEqual(screen.hole(2)?.lit, .top)
        XCTAssertNil(screen.hole(8)?.lit, "hole 8 is under the lower finger")
    }

    func test_cup_whenTurnedOffInTheSettings_opensTheHands() async {
        let screen = await environment.harmonicaScreen()
        _ = await waitUntil { self.environment.phone.isWatched }
        environment.phone.lean(to: 0.6)
        _ = await waitUntil { self.environment.engine.cups.last?.fraction == 0.6 }

        await screen.openTheSettings().turnCupping(on: false)

        XCTAssertEqual(environment.engine.cups.last?.fraction, 0)
    }

    func test_topBar_whenCuppingIsTurnedOffInTheSettings_hidesTheCupOnReturn() async {
        let screen = await environment.harmonicaScreen()
        await screen.openTheSettings().turnCupping(on: false)

        screen.comeBackFromTheSettings()

        XCTAssertFalse(screen.isCupShown)
    }

    func test_cup_whenOffInTheSettings_leavesThePhoneUnwatchedOnReturn() async {
        let screen = await environment.harmonicaScreen()
        await screen.openTheSettings().turnCupping(on: false)
        let watchedBeforeReturning = environment.phone.timesWatched

        screen.comeBackFromTheSettings()
        await Task.megaYield()

        XCTAssertEqual(environment.phone.timesWatched, watchedBeforeReturning)
    }

    func test_square_whenMovedToTheRightInTheSettings_standsRightOfTheHolesOnReturn() async {
        let screen = await environment.harmonicaScreen()
        await screen.openTheSettings().placeSquare(.right)

        screen.comeBackFromTheSettings()

        XCTAssertEqual(screen.squarePlacement, .right)
    }

    func test_square_whenResizedInTheSettings_takesThatSizeOnReturn() async {
        let screen = await environment.harmonicaScreen()
        await screen.openTheSettings().moveTheSizeSlider(to: 1)

        screen.comeBackFromTheSettings()

        XCTAssertEqual(screen.squareSize, SquareSize(clamping: 1))
    }

    // MARK: - Helpers

    private var twoFingersWithHoleTwoOnTop: [StripFinger] {
        [
            StripFinger(fractionFromLeftEdge: 0.15, fractionAboveCentreLine: 0.3),
            StripFinger(fractionFromLeftEdge: 0.75, fractionAboveCentreLine: 0.2),
        ]
    }
}
