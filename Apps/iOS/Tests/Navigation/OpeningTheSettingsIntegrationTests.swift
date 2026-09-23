import XCTest
@testable import MobileHarmonica

@MainActor
final class OpeningTheSettingsIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_settingsButton_whenTapped_opensTheSettings() async {
        let screen = await environment.harmonicaScreen()

        screen.tapTheSettingsButton()

        XCTAssertEqual(environment.coordinator.path, [.settings])
    }
}
