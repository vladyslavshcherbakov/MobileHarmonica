import ComposableArchitecture
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
    func harmonicaViewModel() -> HarmonicaViewModel {
        let instrument = InstrumentGraph(audioEngine: audioEngine, log: log)
        return HarmonicaViewModel(
            playHarmonica: instrument.playHarmonica,
            playScore: instrument.playScore,
            tunes: tunes,
            presenter: HarmonicaPresenter(locale: locale, tunes: tunes),
            log: log
        )
    }

    @MainActor
    func appStore(playingOn harmonica: HarmonicaViewModel) -> StoreOf<AppFeature> {
        let initialState = AppFeature.State(harmonica: HarmonicaFeature.State(settings: settingsRepository.settings()))
        return Store(initialState: initialState) {
            AppFeature()
        } withDependencies: { [tilt, settingsRepository, log] dependencies in
            dependencies.instrument = .playing(on: harmonica)
            dependencies.tilt = .following(tilt)
            dependencies.settingsClient = .storing(in: settingsRepository, log: log)
        }
    }
}
