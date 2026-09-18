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
        return HarmonicaViewModel(
            playHarmonica: playHarmonica,
            playScore: PlayScore(tuning: tuning, harmonica: playHarmonica, log: log),
            presenter: HarmonicaPresenter(locale: .current)
        )
    }
}
