import Foundation
import HarmonicaCore
import XCTest
@testable import MobileHarmonica

final class HarmonicaPresenterUnitTests: XCTestCase {
    private let presenter = HarmonicaPresenter(locale: Locale(identifier: "en_US_POSIX"), tunes: [])

    // MARK: - Tests

    func test_unavailableSound_whenNoRecordingIsBundled_saysTheRecordingsAreMissing() {
        let state = presenter.presentSoundUnavailable(because: .noRecordings)

        XCTAssertEqual(state, .soundUnavailable("Sound is unavailable: the recordings are not in the app."))
    }

    func test_unavailableSound_whenARecordingCannotBeRead_namesTheRecording() {
        let state = presenter.presentSoundUnavailable(because: .recordingUnreadable("hrmnca novbA3"))

        XCTAssertEqual(state, .soundUnavailable("Sound is unavailable: the recording hrmnca novbA3 could not be read."))
    }

    func test_unavailableSound_whenTheOutputRefusesToStart_saysSo() {
        let state = presenter.presentSoundUnavailable(because: .outputRefused)

        XCTAssertEqual(state, .soundUnavailable("Sound is unavailable: the audio output would not start."))
    }
}
