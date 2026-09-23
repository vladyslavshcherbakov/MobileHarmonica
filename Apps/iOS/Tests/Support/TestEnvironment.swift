import Foundation
import HarmonicaCore
import HarmonicaCoreTestSupport
@testable import MobileHarmonica

final class TestEnvironment {
    private let audioEngine: AudioEngineProtocol
    @MainActor private lazy var compositionRoot = CompositionRoot(
        audioEngine: audioEngine,
        tilt: phone,
        defaults: storedSettings.defaults,
        log: log,
        locale: Locale(identifier: "en_US_POSIX"),
        writtenTunes: writtenTunes,
        pauseBeforeATune: pauseBeforeATune
    )

    let engine: RecordingAudioEngine
    let log = RecordingLog()
    let phone = LeaningPhone()
    let storedSettings: IsolatedDefaults
    let pauseBeforeATune: Duration
    let writtenTunes: [Score]
    @MainActor private(set) lazy var coordinator = AppCoordinator()

    // MARK: - Public

    init(
        audioEngine: AudioEngineProtocol? = nil,
        storedSettings: IsolatedDefaults = IsolatedDefaults(),
        pauseBeforeATune: Duration = .zero,
        writtenTunes: [Score] = []
    ) {
        let recordingEngine = RecordingAudioEngine()
        engine = recordingEngine
        self.audioEngine = audioEngine ?? recordingEngine
        self.storedSettings = storedSettings
        self.pauseBeforeATune = pauseBeforeATune
        self.writtenTunes = writtenTunes
    }

    func relaunched() -> TestEnvironment {
        TestEnvironment(storedSettings: storedSettings)
    }

    @MainActor
    func harmonicaScreen() async -> HarmonicaScreenDriver {
        let screen = HarmonicaScreenDriver(compositionRoot.harmonicaViewModel(openSettings: coordinator.openSettings))
        await screen.open()
        return screen
    }

    @MainActor
    func settingsScreen() -> SettingsScreenDriver {
        SettingsScreenDriver(compositionRoot.settingsViewModel())
    }
}
