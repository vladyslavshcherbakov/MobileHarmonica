import Foundation
import HarmonicaCore
import HarmonicaCoreTestSupport
@testable import MobileHarmonica

final class TestEnvironment {
    private let audioEngine: AudioEngineProtocol
    private lazy var compositionRoot = CompositionRoot(
        audioEngine: audioEngine,
        tilt: phone,
        log: log,
        locale: Locale(identifier: "en_US_POSIX"),
        writtenTunes: []
    )

    let engine: RecordingAudioEngine
    let log = RecordingLog()
    let phone = LeaningPhone()

    // MARK: - Public

    init(audioEngine: AudioEngineProtocol? = nil) {
        let recordingEngine = RecordingAudioEngine()
        engine = recordingEngine
        self.audioEngine = audioEngine ?? recordingEngine
    }

    @MainActor
    func harmonicaScreen() async -> HarmonicaScreenDriver {
        let screen = HarmonicaScreenDriver(compositionRoot.harmonicaViewModel())
        await screen.viewModel.prepareSound()
        return screen
    }
}
