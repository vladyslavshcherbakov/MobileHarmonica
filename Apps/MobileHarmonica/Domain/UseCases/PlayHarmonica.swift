final class PlayHarmonica {
    private let tuning: RichterTuning
    private let audioEngine: AudioEngineProtocol
    private var soundingReed: Reed?

    private(set) var key: HarmonicaKey = .c

    // MARK: - Public

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

    func changeKey(to key: HarmonicaKey) -> Hole? {
        self.key = key
        guard let reed = soundingReed else { return nil }

        sound(reed)
        return reed.hole
    }

    func stopPlaying() {
        guard soundingReed != nil else { return }

        audioEngine.silence()
        soundingReed = nil
    }

    // MARK: - Private

    private func sound(_ reed: Reed) {
        audioEngine.soundTone(at: tuning.pitch(for: reed, in: key))
        soundingReed = reed
    }
}
