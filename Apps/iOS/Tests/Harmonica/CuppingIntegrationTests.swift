import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class CuppingIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()
    private var screenOnDisplay: HarmonicaScreenDriver?

    // MARK: - Tests

    func test_cup_whenThePhoneLeans_sendsTheDepthToTheEngine() async {
        await keepTheHarmonicaOnScreen()

        environment.phone.lean(to: 0.6)

        let didTheEngineReceiveTheDepth = await waitUntil { self.environment.engine.cups.last?.fraction == 0.6 }
        XCTAssertTrue(didTheEngineReceiveTheDepth)
    }

    func test_cup_whenThePhoneHoldsStill_sendsTheDepthOnce() async {
        await keepTheHarmonicaOnScreen()

        environment.phone.lean(to: 0.6)
        environment.phone.lean(to: 0.6)
        environment.phone.lean(to: 0.2)

        _ = await waitUntil { self.environment.engine.cups.last?.fraction == 0.2 }
        XCTAssertEqual(environment.engine.cups.map(\.fraction), [0.6, 0.2])
    }

    func test_cup_whenThePhoneLeans_showsHowFarInTheTopBar() async {
        let screen = await environment.harmonicaScreen()

        environment.phone.lean(to: 0.6)

        let isTheDepthDisplayed = await waitUntil { screen.playable?.cup?.closed == 0.6 }
        XCTAssertTrue(isTheDepthDisplayed)
    }

    func test_cup_whenTheHarmonicaIsLeft_stopsWatchingThePhone() async {
        let screen = await environment.harmonicaScreen()

        screen.leave()

        let isThePhoneUnwatched = await waitUntil { !self.environment.phone.isWatched }
        XCTAssertTrue(isThePhoneUnwatched)
    }

    func test_cup_whenTheHarmonicaComesBack_watchesThePhoneAgain() async {
        let screen = await environment.harmonicaScreen()
        screen.leave()

        screen.comeBack()

        XCTAssertEqual(environment.phone.timesWatched, 2)
        XCTAssertTrue(environment.phone.isWatched)
    }

    func test_harmonicaScreen_whenLeftWhileFollowingThePhone_isReleased() async {
        let viewModelLeftBehind = await leaveTheScreenWhileFollowingThePhone()

        XCTAssertNil(viewModelLeftBehind())
    }

    // MARK: - Helpers

    private func keepTheHarmonicaOnScreen() async {
        screenOnDisplay = await environment.harmonicaScreen()
    }

    private func leaveTheScreenWhileFollowingThePhone() async -> () -> HarmonicaViewModel? {
        let screen = await environment.harmonicaScreen()
        screen.leave()
        return { [weak viewModel = screen.viewModel] in viewModel }
    }
}
