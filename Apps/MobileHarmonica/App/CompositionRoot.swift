import Foundation

struct CompositionRoot {
    func harmonicaScreen() -> HarmonicaScreen {
        HarmonicaScreen(viewModel: self.harmonicaViewModel())
    }

    private func harmonicaViewModel() -> HarmonicaViewModel {
        HarmonicaViewModel(
            playHarmonica: PlayHarmonica(tuning: RichterTuning(), audioEngine: audioEngine()),
            presenter: HarmonicaPresenter(locale: .current)
        )
    }

    private func audioEngine() -> AudioEngineProtocol {
        SineWaveAudioEngine(log: TimestampedLog(subsystem: bundleIdentifier(), category: "audio"))
    }

    private func bundleIdentifier() -> String {
        guard let identifier = Bundle.main.bundleIdentifier else {
            preconditionFailure("the app bundle has no CFBundleIdentifier")
        }
        return identifier
    }
}
