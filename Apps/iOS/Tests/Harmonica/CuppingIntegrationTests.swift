import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class CuppingIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_cup_whenThePhoneLeans_tellsTheEngineHowFar() async {
        _ = await followingThePhone()

        environment.phone.lean(to: 0.6)

        let told = await waitUntil { self.environment.engine.cups.last?.fraction == 0.6 }
        XCTAssertTrue(told)
    }

    func test_cup_whenThePhoneHoldsStill_tellsTheEngineOnce() async {
        _ = await followingThePhone()

        environment.phone.lean(to: 0.6)
        environment.phone.lean(to: 0.6)
        environment.phone.lean(to: 0.2)

        _ = await waitUntil { self.environment.engine.cups.last?.fraction == 0.2 }
        XCTAssertEqual(environment.engine.cups.map(\.fraction), [0.6, 0.2])
    }

    func test_cup_whenThePhoneLeans_showsHowFarInTheTopBar() async {
        let screen = await followingThePhone()

        environment.phone.lean(to: 0.6)

        let shown = await waitUntil { screen.playable?.cup.closed == 0.6 }
        XCTAssertTrue(shown)
    }

    func test_cup_whenTheUserLeavesTheScreen_stopsWatchingThePhone() async {
        let screen = await followingThePhone()

        await screen.leave()

        let stopped = await waitUntil { !self.environment.phone.isWatched }
        XCTAssertTrue(stopped)
    }

    func test_harmonicaScreen_whenLeftWhileFollowingThePhone_isReleased() async {
        let leftBehind = await leaveTheScreenWhileFollowingThePhone()

        let released = await waitUntil { leftBehind() == nil }
        XCTAssertTrue(released)
    }

    // MARK: - Helpers

    private func followingThePhone() async -> HarmonicaScreenDriver {
        let screen = await environment.harmonicaScreen()
        _ = await waitUntil { self.environment.phone.isWatched }
        return screen
    }

    private func leaveTheScreenWhileFollowingThePhone() async -> () -> HarmonicaViewModel? {
        let screen = await followingThePhone()
        await screen.leave()
        return { [weak viewModel = screen.viewModel] in viewModel }
    }
}
