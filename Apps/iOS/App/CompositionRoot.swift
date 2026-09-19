import HarmonicaCore

struct CompositionRoot {
    private let audioEngine: AudioEngineProtocol
    private let tilt: TiltProtocol
    private let log: LogProtocol

    init(audioEngine: AudioEngineProtocol, tilt: TiltProtocol, log: LogProtocol) {
        self.audioEngine = audioEngine
        self.tilt = tilt
        self.log = log
    }

    @MainActor
    func harmonicaScreen() -> HarmonicaScreen {
        HarmonicaScreen(viewModel: self.harmonicaViewModel())
    }

    @MainActor
    private func harmonicaViewModel() -> HarmonicaViewModel {
        let tuning = RichterTuning()
        let playHarmonica = PlayHarmonica(tuning: tuning, audioEngine: audioEngine, log: log)
        let tunes = [BundledScores(tuning: tuning, log: log).first()].compactMap { $0 } + Score.tunes
        return HarmonicaViewModel(
            playHarmonica: playHarmonica,
            playScore: PlayScore(tuning: tuning, harmonica: playHarmonica, log: log),
            tilt: tilt,
            tunes: tunes,
            presenter: HarmonicaPresenter(locale: .current, tunes: tunes)
        )
    }
}
