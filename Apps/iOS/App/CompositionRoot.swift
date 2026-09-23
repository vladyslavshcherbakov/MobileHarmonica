import Foundation
import HarmonicaCore

struct CompositionRoot {
    private let audioEngine: AudioEngineProtocol
    private let tilt: TiltProtocol
    private let settingsRepository: SettingsRepository
    private let log: LogProtocol
    private let locale: Locale
    private let tunes: [Score]

    init(
        audioEngine: AudioEngineProtocol,
        tilt: TiltProtocol,
        defaults: UserDefaults,
        log: LogProtocol,
        locale: Locale,
        writtenTunes: [Score]
    ) {
        self.audioEngine = audioEngine
        self.tilt = tilt
        settingsRepository = SettingsRepository(defaults: defaults, log: log)
        self.log = log
        self.locale = locale
        tunes = writtenTunes + Score.tunes
    }

    @MainActor
    func harmonicaScreen(openSettings: @escaping @MainActor () -> Void) -> HarmonicaScreen {
        HarmonicaScreen(viewModel: self.harmonicaViewModel(), openSettings: openSettings)
    }

    @MainActor
    func settingsScreen() -> SettingsScreen {
        SettingsScreen(viewModel: self.settingsViewModel())
    }

    @MainActor
    func harmonicaViewModel() -> HarmonicaViewModel {
        let instrument = InstrumentGraph(audioEngine: audioEngine, log: log)
        return HarmonicaViewModel(
            playHarmonica: instrument.playHarmonica,
            playScore: instrument.playScore,
            tilt: tilt,
            settingsRepository: settingsRepository,
            tunes: tunes,
            presenter: HarmonicaPresenter(locale: locale, tunes: tunes),
            log: log
        )
    }

    @MainActor
    func settingsViewModel() -> SettingsViewModel {
        SettingsViewModel(repository: settingsRepository, presenter: SettingsPresenter(), log: log)
    }
}
