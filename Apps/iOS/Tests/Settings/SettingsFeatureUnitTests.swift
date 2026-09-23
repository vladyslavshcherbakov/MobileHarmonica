import ComposableArchitecture
import XCTest
@testable import MobileHarmonica

@MainActor
final class SettingsFeatureUnitTests: XCTestCase {
    private let oneFingerChosen = PlayerSettings(
        style: .oneFingerSeveralNotes,
        isCuppingEnabled: true,
        squarePlacement: .left,
        squareSize: .atFirstLaunch
    )

    // MARK: - Tests

    func test_playingStyle_whenChosen_isSavedAndHandedToTheHarmonica() async {
        let saved = LockIsolated<[PlayerSettings]>([])
        let store = TestStore(initialState: SettingsFeature.State(settings: .atFirstLaunch)) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsClient = SettingsClient(save: { settings in saved.withValue { $0.append(settings) } })
        }

        await store.send(.styleChosen(.oneFingerSeveralNotes)) { $0.settings = self.oneFingerChosen }

        await store.receive(\.delegate.settingsChanged, oneFingerChosen)
        XCTAssertEqual(saved.value, [oneFingerChosen])
    }

    func test_playingStyle_whenTheChosenOneIsChosenAgain_changesNothing() async {
        let store = TestStore(initialState: SettingsFeature.State(settings: .atFirstLaunch)) {
            SettingsFeature()
        }

        await store.send(.styleChosen(.severalFingersSeveralNotes))
    }
}
