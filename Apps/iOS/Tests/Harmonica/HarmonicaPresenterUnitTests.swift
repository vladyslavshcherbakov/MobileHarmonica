import XCTest
@testable import MobileHarmonica

final class HarmonicaPresenterUnitTests: XCTestCase {
    // MARK: - Tests

    func test_unavailableSound_whenNoRecordingIsBundled_saysTheRecordingsAreMissing() {
        let text = HarmonicaPresenter.unavailableText(because: .noRecordings)

        XCTAssertEqual(text, "Sound is unavailable: the recordings are not in the app.")
    }

    func test_unavailableSound_whenARecordingCannotBeRead_namesTheRecording() {
        let text = HarmonicaPresenter.unavailableText(because: .recordingUnreadable("hrmnca novbA3"))

        XCTAssertEqual(text, "Sound is unavailable: the recording hrmnca novbA3 could not be read.")
    }

    func test_unavailableSound_whenTheOutputRefusesToStart_saysSo() {
        let text = HarmonicaPresenter.unavailableText(because: .outputRefused)

        XCTAssertEqual(text, "Sound is unavailable: the audio output would not start.")
    }
}
