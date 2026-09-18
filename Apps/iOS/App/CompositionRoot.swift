struct CompositionRoot {
    private let audioEngine: AudioEngineProtocol
    private let log: LogProtocol

    init(audioEngine: AudioEngineProtocol, log: LogProtocol) {
        self.audioEngine = audioEngine
        self.log = log
    }

    func harmonicaScreen() -> HarmonicaScreen {
        HarmonicaScreen(viewModel: self.harmonicaViewModel())
    }

    private func harmonicaViewModel() -> HarmonicaViewModel {
        let tuning = RichterTuning()
        let playHarmonica = PlayHarmonica(tuning: tuning, audioEngine: audioEngine, log: log)
        let tunes = [BundledScores(tuning: tuning, log: log).first()].compactMap { $0 } + Score.tunes
        return HarmonicaViewModel(
            playHarmonica: playHarmonica,
            playScore: PlayScore(tuning: tuning, harmonica: playHarmonica, log: log),
            tunes: tunes,
            presenter: HarmonicaPresenter(locale: .current, tunes: tunes.map(\.name))
        )
    }
}
