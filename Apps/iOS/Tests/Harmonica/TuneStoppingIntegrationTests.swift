import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class TuneStoppingIntegrationTests: XCTestCase {
    private static let scoreStoppedLine = "score stopped early"

    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_demo_whenAFingerTouchesTheStrip_stopsTheTuneAndSoundsTheFinger() async {
        let screen = await playingTheFirstTune()

        screen.touchStrip(at: 0.35, above: 0.2)

        let scoreStopped = await waitUntil { self.environment.log.lines.contains(Self.scoreStoppedLine) }
        XCTAssertTrue(scoreStopped)
        XCTAssertEqual(screen.playable?.demo.isPlaying, false)
        XCTAssertEqual(screen.hole(4)?.note, "C5", "the finger's hole 4 blown is what is heard")
    }

    func test_demo_whenStopped_ringsTheReedsDown() async {
        let screen = await playingTheFirstTune()

        screen.stopTheTune()

        XCTAssertEqual(environment.engine.releases.last, .ringsDown)
        XCTAssertEqual(screen.playable?.demo.isPlaying, false)
    }

    func test_harmonicaScreen_whenLeftWhileATunePlays_stopsTheTune() async {
        _ = await leaveTheScreenWhileTheFirstTunePlays()

        let scoreStopped = await waitUntil { self.environment.log.lines.contains(Self.scoreStoppedLine) }
        XCTAssertTrue(scoreStopped)
    }

    func test_harmonicaScreen_whenLeftWhileATunePlays_isReleased() async {
        let viewModelLeftBehind = await leaveTheScreenWhileTheFirstTunePlays()

        let released = await waitUntil { viewModelLeftBehind() == nil }
        XCTAssertTrue(released)
    }

    // MARK: - Helpers

    private func playingTheFirstTune() async -> HarmonicaScreenDriver {
        let screen = await environment.harmonicaScreen()
        screen.playTune(at: 0)
        _ = await waitUntil { !self.environment.engine.soundedTones.isEmpty }
        return screen
    }

    private func leaveTheScreenWhileTheFirstTunePlays() async -> () -> HarmonicaViewModel? {
        let screen = await playingTheFirstTune()
        await screen.leave()
        return { [weak viewModel = screen.viewModel] in viewModel }
    }
}
