import XCTest
@testable import MobileHarmonica

final class SettingsPresenterUnitTests: XCTestCase {
    // MARK: - Tests

    func test_styleChoices_nameEveryStyleAsAFullSentence() {
        let state = SettingsPresenter().present(.atFirstLaunch)

        XCTAssertEqual(
            state.style.choices.map(\.name),
            ["Many fingers, many notes", "Many fingers, one note", "One finger, many notes"]
        )
    }

    func test_squarePlacementChoices_sayWhichSideOfTheHolesTheSquareStands() {
        let state = SettingsPresenter().present(.atFirstLaunch)

        XCTAssertEqual(state.squarePlacement.choices.map(\.name), ["Left of the holes", "Right of the holes"])
    }
}
