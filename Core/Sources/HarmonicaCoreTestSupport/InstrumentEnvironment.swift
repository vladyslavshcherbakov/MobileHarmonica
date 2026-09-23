import HarmonicaCore

public final class InstrumentEnvironment {
    public let engine = RecordingAudioEngine()
    public let log = RecordingLog()
    public lazy var instrument = InstrumentGraph(audioEngine: engine, log: log)

    public init() {}

    public var playHarmonica: PlayHarmonicaUseCase {
        instrument.playHarmonica
    }

    public var playScore: PlayScoreUseCase {
        instrument.playScore
    }
}
