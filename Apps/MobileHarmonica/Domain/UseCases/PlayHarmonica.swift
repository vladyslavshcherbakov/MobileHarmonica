final class PlayHarmonica {
    private let tuning: RichterTuning
    private let audioEngine: AudioEngineProtocol
    private var soundingReeds: [Reed] = []

    private(set) var key: HarmonicaKey = .c

    // MARK: - Public

    init(tuning: RichterTuning, audioEngine: AudioEngineProtocol) {
        self.tuning = tuning
        self.audioEngine = audioEngine
    }

    func prepare() async throws {
        try await audioEngine.prepare()
    }

    func play(at positions: [PositionOnHarmonica]) -> Set<Hole> {
        let reeds = reedsUnder(positions)
        guard !reeds.isEmpty else {
            stopPlaying()
            return []
        }
        guard reeds != soundingReeds else { return soundingHoles }

        sound(reeds)
        return soundingHoles
    }

    func changeKey(to key: HarmonicaKey) -> Set<Hole> {
        self.key = key
        guard !soundingReeds.isEmpty else { return [] }

        sound(soundingReeds)
        return soundingHoles
    }

    func stopPlaying() {
        guard !soundingReeds.isEmpty else { return }

        audioEngine.silence()
        soundingReeds = []
    }

    // MARK: - Private

    private var soundingHoles: Set<Hole> {
        Set(soundingReeds.map(\.hole))
    }

    private func reedsUnder(_ positions: [PositionOnHarmonica]) -> [Reed] {
        guard let breath = Breath(topmostOf: positions) else { return [] }

        return holesUnder(positions).map { Reed(hole: $0, breath: breath) }
    }

    private func holesUnder(_ positions: [PositionOnHarmonica]) -> [Hole] {
        Set(positions.compactMap(Hole.init(at:))).sorted { $0.number < $1.number }
    }

    private func sound(_ reeds: [Reed]) {
        audioEngine.soundTones(at: reeds.map { tuning.pitch(for: $0, in: key) })
        soundingReeds = reeds
    }
}
