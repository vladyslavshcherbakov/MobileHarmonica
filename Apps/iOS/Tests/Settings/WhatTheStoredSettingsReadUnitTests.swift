import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

final class WhatTheStoredSettingsReadUnitTests: XCTestCase {
    private let storedSettings = IsolatedDefaults()
    private let log = RecordingLog()

    // MARK: - Tests

    func test_storedSettings_whenNothingWasStored_areTheFirstLaunchOnes() {
        let settings = repository().settings()

        XCTAssertEqual(settings, .atFirstLaunch)
    }

    func test_storedSettings_whenSaved_readBackAsTheyWere() {
        let saved = PlayerSettings(
            style: .severalFingersOneNote,
            isCuppingEnabled: false,
            squarePlacement: .right,
            squareSize: SquareSize(clamping: 0.25)
        )

        repository().save(saved)

        XCTAssertEqual(repository().settings(), saved)
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
        storedSettings.defaults.set(3.0, forKey: "settings.squareSize")

        let settings = repository().settings()

        XCTAssertEqual(settings.squareSize.fraction, 1)
    }

    // MARK: - Helpers

    private func repository() -> SettingsRepository {
        SettingsRepository(defaults: storedSettings.defaults, log: log)
    }
}
