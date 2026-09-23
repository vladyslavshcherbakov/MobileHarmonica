public struct InstrumentGraph {
    public let playHarmonica: PlayHarmonicaUseCase
    public let playScore: PlayScoreUseCase

    public init(audioEngine: AudioEngineProtocol, log: LogProtocol) {
        let tuning = RichterTuning()
        playHarmonica = PlayHarmonicaUseCase(tuning: tuning, audioEngine: audioEngine, log: log)
        playScore = PlayScoreUseCase(tuning: tuning, harmonica: playHarmonica, log: log)
    }
}
