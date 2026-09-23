import ComposableArchitecture
import Foundation
import HarmonicaCore
import HarmonicaCoreTestSupport
@testable import MobileHarmonica

final class TestEnvironment {
    private let audioEngine: AudioEngineProtocol
    private lazy var compositionRoot = CompositionRoot(
        audioEngine: audioEngine,
        tilt: phone,
        defaults: storedSettings.defaults,
        log: log,
        locale: Locale(identifier: "en_US_POSIX"),
        writtenTunes: []
    )

    let engine: RecordingAudioEngine
    let log = RecordingLog()
    let phone = LeaningPhone()
    let storedSettings: IsolatedDefaults

    // MARK: - Public

    init(audioEngine: AudioEngineProtocol? = nil, storedSettings: IsolatedDefaults = IsolatedDefaults()) {
        let recordingEngine = RecordingAudioEngine()
        engine = recordingEngine
        self.audioEngine = audioEngine ?? recordingEngine
        self.storedSettings = storedSettings
    }

    func relaunched() -> TestEnvironment {
        TestEnvironment(storedSettings: storedSettings)
    }

    @MainActor
    func harmonicaScreen() async -> HarmonicaScreenDriver {
        let screen = launched()
        await screen.open()
        return screen
    }

    @MainActor
    func settingsScreen() async -> SettingsScreenDriver {
        await launched().openTheSettings()
    }

    // MARK: - Private

    @MainActor
    private func launched() -> HarmonicaScreenDriver {
        let harmonica = compositionRoot.harmonicaViewModel()
        return HarmonicaScreenDriver(store: compositionRoot.appStore(playingOn: harmonica), viewModel: harmonica)
    }
}
