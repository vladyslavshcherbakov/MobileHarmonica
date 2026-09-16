final class PlayHarmonica {
    private let tuning: RichterTuning
    private let audioEngine: AudioEngineProtocol
    private var soundingReed: Reed?

    init(tuning: RichterTuning, audioEngine: AudioEngineProtocol) {
        self.tuning = tuning
        self.audioEngine = audioEngine
    }

    func prepare() async throws {
        try await audioEngine.prepare()
    }

    func play(at position: PositionOnHarmonica) -> Hole? {
        guard let reed = Reed(at: position) else {
            stopPlaying()
            return nil
        }
        guard reed != soundingReed else { return reed.hole }

        sound(reed)
        return reed.hole
    }

    func stopPlaying() {
        guard soundingReed != nil else { return }

        audioEngine.silence()
        soundingReed = nil
    }

    private func sound(_ reed: Reed) {
        audioEngine.soundTone(at: tuning.pitch(for: reed))
        soundingReed = reed
    }
}
