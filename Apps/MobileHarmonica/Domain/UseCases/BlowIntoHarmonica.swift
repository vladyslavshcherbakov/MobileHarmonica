final class BlowIntoHarmonica {
    private let tuning: RichterTuning
    private let audioEngine: AudioEngineProtocol
    private var soundingHole: Hole?

    init(tuning: RichterTuning, audioEngine: AudioEngineProtocol) {
        self.tuning = tuning
        self.audioEngine = audioEngine
    }

    func prepare() throws {
        try audioEngine.prepare()
    }

    func blow(at position: PositionAlongHarmonica) -> Hole? {
        guard let hole = Hole(at: position) else {
            stopBlowing()
            return nil
        }
        guard hole != soundingHole else { return hole }

        sound(hole)
        return hole
    }

    func stopBlowing() {
        guard soundingHole != nil else { return }

        audioEngine.stopTone()
        soundingHole = nil
    }

    private func sound(_ hole: Hole) {
        audioEngine.stopTone()
        audioEngine.startTone(at: tuning.blowPitch(for: hole))
        soundingHole = hole
    }
}
