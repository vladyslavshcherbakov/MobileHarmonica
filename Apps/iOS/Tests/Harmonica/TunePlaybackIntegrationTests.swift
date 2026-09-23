import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class TunePlaybackIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_tune_whenItSoundsANote_hasLitItsHoleBeforeAnythingElseRuns() async {
        let screen = await environment.harmonicaScreen()
        let seen = LitHolesAfterEachTone()
        environment.engine.toneSounded = {
            Task { @MainActor in seen.record(screen.playable?.holes.filter { $0.lit != nil }.map(\.id) ?? []) }
        }

        screen.playTune(at: 0)

        _ = await waitUntil { !seen.recorded.isEmpty }
        XCTAssertNotEqual(seen.recorded.first, [], "the first note of the blues lights its holes as it sounds")
    }

    func test_demoButton_whenATunePlays_namesTheTune() async {
        let screen = await environment.harmonicaScreen()

        screen.playTune(at: 0)

        XCTAssertEqual(screen.playable?.demo.label, "■\u{FE0E} Blues strain")
    }

    func test_demoButton_whenNothingPlays_offersToPlay() async {
        let screen = await environment.harmonicaScreen()

        XCTAssertEqual(screen.playable?.demo.label, "▶\u{FE0E}")
    }
}

// MARK: - LitHolesAfterEachTone

@MainActor
private final class LitHolesAfterEachTone {
    private(set) var recorded: [[Int]] = []

    func record(_ holes: [Int]) {
        recorded.append(holes)
    }
}
