import XCTest
@testable import MobileHarmonica

@MainActor
final class SettingsPersistenceIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_settingsScreen_whenOpenedForTheFirstTime_showsHowTheHarmonicaPlaysOutOfTheBox() async {
        let settings = await environment.settingsScreen()

        XCTAssertEqual(settings.state.style.chosen, .severalFingersSeveralNotes)
        XCTAssertEqual(settings.state.cupping.isOn, true)
        XCTAssertEqual(settings.state.squarePlacement.chosen, .left)
        XCTAssertEqual(settings.state.squareSize.fraction, 0.4)
    }

    func test_playingStyle_whenChosen_isStillChosenAfterARelaunch() async {
        await environment.settingsScreen().chooseStyle(.oneFingerSeveralNotes)

        let settings = await environment.relaunched().settingsScreen()

        XCTAssertEqual(settings.state.style.chosen, .oneFingerSeveralNotes)
    }

    func test_cupping_whenTurnedOff_isStillOffAfterARelaunch() async {
        await environment.settingsScreen().turnCupping(on: false)

        let settings = await environment.relaunched().settingsScreen()

        XCTAssertEqual(settings.state.cupping.isOn, false)
    }

    func test_squarePlacement_whenMovedToTheRight_isStillOnTheRightAfterARelaunch() async {
        await environment.settingsScreen().placeSquare(.right)

        let settings = await environment.relaunched().settingsScreen()

        XCTAssertEqual(settings.state.squarePlacement.chosen, .right)
    }

    func test_squareSize_whenSetWithTheSlider_isStillSetAfterARelaunch() async {
        await environment.settingsScreen().moveTheSizeSlider(to: 0.75)

        let settings = await environment.relaunched().settingsScreen()

        XCTAssertEqual(settings.state.squareSize.fraction, 0.75)
    }

    func test_squareSize_whenPinchedToTheLargest_showsTheSliderAtTheTop() async {
        let screen = await environment.harmonicaScreen()

        await screen.pinchTheSquare(by: 10)

        let settings = await screen.openTheSettings()
        XCTAssertEqual(settings.state.squareSize.fraction, 1)
    }

    func test_squareSize_whenPinched_isStillThatSizeAfterARelaunch() async {
        let screen = await environment.harmonicaScreen()

        await screen.pinchTheSquare(by: 0.1)

        let relaunched = await environment.relaunched().harmonicaScreen()
        XCTAssertEqual(relaunched.squareSize, SquareSize(clamping: 0))
    }
}
