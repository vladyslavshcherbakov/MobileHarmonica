import XCTest
@testable import MobileHarmonica

@MainActor
final class WhatTheSettingsKeepIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_settingsScreen_whenOpenedForTheFirstTime_showsHowTheHarmonicaPlaysOutOfTheBox() {
        let settings = environment.settingsScreen()

        XCTAssertEqual(settings.state.style.chosen, .severalFingersSeveralNotes)
        XCTAssertEqual(settings.state.cupping.isOn, true)
        XCTAssertEqual(settings.state.squarePlacement.chosen, .left)
        XCTAssertEqual(settings.state.squareSize.fraction, 0.4)
    }

    func test_playingStyle_whenChosen_isStillChosenAfterARelaunch() {
        environment.settingsScreen().chooseStyle(.oneFingerSeveralNotes)

        let settings = environment.relaunched().settingsScreen()

        XCTAssertEqual(settings.state.style.chosen, .oneFingerSeveralNotes)
    }

    func test_cupping_whenTurnedOff_isStillOffAfterARelaunch() {
        environment.settingsScreen().turnCupping(on: false)

        let settings = environment.relaunched().settingsScreen()

        XCTAssertEqual(settings.state.cupping.isOn, false)
    }

    func test_squarePlacement_whenMovedToTheRight_isStillOnTheRightAfterARelaunch() {
        environment.settingsScreen().placeSquare(.right)

        let settings = environment.relaunched().settingsScreen()

        XCTAssertEqual(settings.state.squarePlacement.chosen, .right)
    }

    func test_squareSize_whenSetWithTheSlider_isStillSetAfterARelaunch() {
        environment.settingsScreen().moveTheSizeSlider(to: 0.75)

        let settings = environment.relaunched().settingsScreen()

        XCTAssertEqual(settings.state.squareSize.fraction, 0.75)
    }

    func test_squareSize_whenPinchedToTheLargest_showsTheSliderAtTheTop() async {
        let screen = await environment.harmonicaScreen()

        screen.pinchTheSquare(by: 10)

        XCTAssertEqual(environment.settingsScreen().state.squareSize.fraction, 1)
    }

    func test_squareSize_whenPinched_isStillThatSizeAfterARelaunch() async {
        let screen = await environment.harmonicaScreen()

        screen.pinchTheSquare(by: 0.1)

        let relaunched = await environment.relaunched().harmonicaScreen()
        XCTAssertEqual(relaunched.playable?.square.size, SquareSize(clamping: 0))
    }
}
