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
        HarmonicaViewModel(
            playHarmonica: PlayHarmonica(tuning: RichterTuning(), audioEngine: audioEngine, log: log),
            presenter: HarmonicaPresenter(locale: .current)
        )
    }
}
