import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class WhatCuppingTheHandsDoesIntegrationTests: XCTestCase {
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

        let shown = await waitUntil { screen.playable?.cup?.closed == 0.6 }
        XCTAssertTrue(shown)
    }

    func test_cup_whenTheScreenStopsFollowingThePhone_stopsWatchingIt() async {
        let screen = await environment.harmonicaScreen()
        let following = Task { await screen.followThePhone() }
        _ = await waitUntil { self.environment.phone.isWatched }

        following.cancel()
        await following.value

        XCTAssertFalse(environment.phone.isWatched)
    }

    func test_harmonicaScreen_whenLeftWhileFollowingThePhone_isReleased() async {
        let viewModelLeftBehind = await leaveTheScreenWhileFollowingThePhone()

        XCTAssertNil(viewModelLeftBehind())
    }

    // MARK: - Helpers

    private func followingThePhone() async -> HarmonicaScreenDriver {
        let screen = await environment.harmonicaScreen()
        let following = Task { await screen.followThePhone() }
        addTeardownBlock { following.cancel() }
        _ = await waitUntil { self.environment.phone.isWatched }
        return screen
    }

    private func leaveTheScreenWhileFollowingThePhone() async -> () -> HarmonicaViewModel? {
        let screen = await environment.harmonicaScreen()
        let following = Task { await screen.followThePhone() }
        _ = await waitUntil { self.environment.phone.isWatched }
        following.cancel()
        await following.value
        return { [weak viewModel = screen.viewModel] in viewModel }
    }
}
