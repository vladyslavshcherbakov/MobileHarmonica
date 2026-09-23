import Combine
import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class SettingsRepositoryUnitTests: XCTestCase {
    private let storedSettings = IsolatedDefaults()
    private let log = RecordingLog()

    // MARK: - Tests

    func test_storedSettings_whenNothingWasStored_areTheFirstLaunchOnes() {
        let settings = repository().settings()

        XCTAssertEqual(settings, .atFirstLaunch)
    }

    func test_storedSettings_whenSaved_readBackAsTheyWere() {
        repository().save(changedSettings)

        XCTAssertEqual(repository().settings(), changedSettings)
    }

    func test_savedSettings_whenSaved_reachEverySubscriber() {
        let repository = self.repository()
        var receivedSettings: [PlayerSettings] = []
        let subscription = repository.savedSettings.sink { receivedSettings.append($0) }

        repository.save(changedSettings)

        XCTAssertEqual(receivedSettings, [changedSettings])
        subscription.cancel()
    }

    func test_storedSettings_whenTheStyleIsOneThisBuildDoesNotKnow_playTheFirstLaunchStyleAndSaySo() {
        storedSettings.defaults.set("twoHandsManyNotes", forKey: "settings.playingStyle")

        let settings = repository().settings()

        XCTAssertEqual(settings.style, .severalFingersSeveralNotes)
        XCTAssertEqual(
            log.lines,
            ["stored settings.playingStyle is twoHandsManyNotes, which this build does not know, the first launch value is used"]
        )
    }

    func test_storedSettings_whenTheSizeIsPastTheLargest_readAsTheLargest() {
        storedSettings.defaults.set(3.0, forKey: "settings.shapingPadSize")

        let settings = repository().settings()

        XCTAssertEqual(settings.shapingPadSize.fraction, 1)
    }

    // MARK: - Helpers

    private var changedSettings: PlayerSettings {
        PlayerSettings(
            style: .severalFingersOneNote,
            isCuppingEnabled: false,
            shapingPadPlacement: .right,
            shapingPadSize: ShapingPadSize(clamping: 0.25)
        )
    }

    private func repository() -> SettingsRepository {
        SettingsRepository(defaults: storedSettings.defaults, log: log)
    }
}
