import Foundation
import HarmonicaCore

struct CompositionRoot {
    private let audioEngine: AudioEngineProtocol
    private let tilt: TiltProtocol
    private let settingsRepository: SettingsRepository
    private let log: LogProtocol
    private let locale: Locale
    private let tunes: [Score]
    private let pauseBeforeATune: Duration

    @MainActor
    init(
        audioEngine: AudioEngineProtocol,
        tilt: TiltProtocol,
        defaults: UserDefaults,
        log: LogProtocol,
        locale: Locale,
        writtenTunes: [Score],
        pauseBeforeATune: Duration
    ) {
        self.audioEngine = audioEngine
        self.tilt = tilt
        settingsRepository = SettingsRepository(defaults: defaults, log: log)
        self.log = log
        self.locale = locale
        tunes = Score.tunes + writtenTunes
        self.pauseBeforeATune = pauseBeforeATune
    }

    @MainActor
    func harmonicaScreen(openSettings: @escaping @MainActor () -> Void) -> HarmonicaScreen {
        HarmonicaScreen(viewModel: self.harmonicaViewModel(openSettings: openSettings))
    }

    @MainActor
    func settingsScreen() -> SettingsScreen {
        SettingsScreen(viewModel: self.settingsViewModel())
    }

    @MainActor
    func harmonicaViewModel(openSettings: @escaping @MainActor () -> Void) -> HarmonicaViewModel {
        let instrument = InstrumentGraph(audioEngine: audioEngine, log: log)
        return HarmonicaViewModel(
            playHarmonica: instrument.playHarmonica,
            playScore: instrument.playScore,
            tilt: tilt,
            settingsRepository: settingsRepository,
            tunes: tunes,
            presenter: HarmonicaPresenter(locale: locale, tunes: tunes),
            log: log,
            pauseBeforeATune: pauseBeforeATune,
            openSettings: openSettings
        )
    }

    @MainActor
    func settingsViewModel() -> SettingsViewModel {
        SettingsViewModel(repository: settingsRepository, presenter: SettingsPresenter(), log: log)
    }
}
