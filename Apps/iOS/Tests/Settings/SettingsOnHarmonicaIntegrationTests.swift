import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class SettingsOnHarmonicaIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_harmonica_whenOneFingerIsChosenInTheSettings_soundsOnlyTheTopmostFingerOnReturn() async {
        let screen = await environment.harmonicaScreen()
        screen.leave()
        environment.settingsScreen().chooseStyle(.oneFingerSeveralNotes)
        screen.comeBack()

        screen.touchStrip(with: twoFingersWithHoleTwoOnTop)

        XCTAssertEqual(screen.hole(2)?.lit, .top)
        XCTAssertNil(screen.hole(8)?.lit, "hole 8 is under the lower finger")
    }

    func test_harmonica_whenLaunchedWithOneFingerChosen_soundsOnlyTheTopmostFinger() async {
        environment.settingsScreen().chooseStyle(.oneFingerSeveralNotes)
        let screen = await environment.relaunched().harmonicaScreen()

        screen.touchStrip(with: twoFingersWithHoleTwoOnTop)

        XCTAssertEqual(screen.hole(2)?.lit, .top)
        XCTAssertNil(screen.hole(8)?.lit, "hole 8 is under the lower finger")
    }

    func test_cup_whenTurnedOffInTheSettings_opensTheHandsOnReturn() async {
        let screen = await environment.harmonicaScreen()
        environment.phone.lean(to: 0.6)
        _ = await waitUntil { self.environment.engine.cups.last?.fraction == 0.6 }
        screen.leave()
        environment.settingsScreen().turnCupping(on: false)

        screen.comeBack()

        XCTAssertEqual(environment.engine.cups.last?.fraction, 0)
    }

    func test_cup_whenTurnedOffInTheSettings_leavesThePhoneUnwatchedOnReturn() async {
        let screen = await environment.harmonicaScreen()
        screen.leave()
        environment.settingsScreen().turnCupping(on: false)

        screen.comeBack()

        XCTAssertEqual(environment.phone.timesWatched, 1, "watched only before the settings were opened")
    }

    func test_topBar_whenCuppingIsTurnedOffInTheSettings_hidesTheCupOnReturn() async {
        let screen = await environment.harmonicaScreen()
        screen.leave()
        environment.settingsScreen().turnCupping(on: false)

        screen.comeBack()

        XCTAssertNil(screen.playable?.cup)
    }

    func test_cup_whenOffInTheSettings_leavesThePhoneUnwatched() async {
        environment.settingsScreen().turnCupping(on: false)
        _ = await environment.harmonicaScreen()

        XCTAssertEqual(environment.phone.timesWatched, 0)
    }

    func test_shapingPad_whenMovedToTheRightInTheSettings_standsRightOfTheHolesOnReturn() async {
        let screen = await environment.harmonicaScreen()
        screen.leave()
        environment.settingsScreen().placeShapingPad(.right)

        screen.comeBack()

        XCTAssertEqual(screen.playable?.shapingPad.placement, .right)
    }

    func test_shapingPad_whenResizedInTheSettings_takesThatSizeOnReturn() async {
        let screen = await environment.harmonicaScreen()
        screen.leave()
        environment.settingsScreen().moveTheSizeSlider(to: 1)

        screen.comeBack()

        XCTAssertEqual(screen.playable?.shapingPad.size, ShapingPadSize(clamping: 1))
    }

    // MARK: - Helpers

    private var twoFingersWithHoleTwoOnTop: [StripFinger] {
        [
            StripFinger(fractionFromLeftEdge: 0.15, fractionAboveCentreLine: 0.3),
            StripFinger(fractionFromLeftEdge: 0.75, fractionAboveCentreLine: 0.2),
        ]
    }
}
