import HarmonicaCore
import XCTest
@testable import MobileHarmonica

@MainActor
final class TuneMenuIntegrationTests: XCTestCase {

    // MARK: - Tests

    func test_tuneMenu_whenAScoreIsWritten_listsItAfterTheBuiltInTunes() async {
        let environment = TestEnvironment(writtenTunes: [
            Score(name: "Written by hand", key: .c, position: .first, beatsPerMinute: 100, events: [])
        ])

        let screen = await environment.harmonicaScreen()

        XCTAssertEqual(
            screen.playable?.demo.tunes.map(\.name),
            ["Blues strain", "Slow drag", "Oi pid vyshneiu", "The Star-Spangled Banner", "Written by hand"],
            "the built-in tunes keep the numbers they have on the page"
        )
    }
}
