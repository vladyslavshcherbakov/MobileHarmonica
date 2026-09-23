import Foundation
import HarmonicaCore

struct CompositionRoot {
    private let audioEngine: AudioEngineProtocol
    private let tilt: TiltProtocol
    private let log: LogProtocol
    private let locale: Locale
    private let tunes: [Score]

    init(
        audioEngine: AudioEngineProtocol,
        tilt: TiltProtocol,
        log: LogProtocol,
        locale: Locale,
        writtenTunes: [Score]
    ) {
        self.audioEngine = audioEngine
        self.tilt = tilt
        self.log = log
        self.locale = locale
        tunes = writtenTunes + Score.tunes
    }

    @MainActor
    func harmonicaScreen() -> HarmonicaScreen {
        HarmonicaScreen(viewModel: self.harmonicaViewModel())
    }

    @MainActor
    func harmonicaViewModel() -> HarmonicaViewModel {
        let instrument = InstrumentGraph(audioEngine: audioEngine, log: log)
        return HarmonicaViewModel(
            playHarmonica: instrument.playHarmonica,
            playScore: instrument.playScore,
            tilt: tilt,
            tunes: tunes,
            presenter: HarmonicaPresenter(locale: locale, tunes: tunes),
            log: log
        )
    }
}
