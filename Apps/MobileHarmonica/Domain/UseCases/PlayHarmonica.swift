final class PlayHarmonica {
    private let tuning: RichterTuning
    private let audioEngine: AudioEngineProtocol
    private var soundingReeds: [Reed] = []
    private var soundingIntensity: BreathIntensity?
    private var bend: BendDepth = .unbent
    private var vibrato: VibratoDepth = .off

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
        guard !reeds.isEmpty, let intensity = intensityOf(positions) else {
            stopPlaying()
            return []
        }

        applyBreathIntensity(intensity)
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

    func shapeTone(bend: BendDepth, vibrato: VibratoDepth) {
        guard bend != self.bend || vibrato != self.vibrato else { return }

        self.bend = bend
        self.vibrato = vibrato
        audioEngine.changeBend(to: bend)
        audioEngine.changeVibrato(to: vibrato)
    }

    func stopPlaying() {
        guard !soundingReeds.isEmpty else { return }

        audioEngine.silence()
        soundingReeds = []
        soundingIntensity = nil
    }

    // MARK: - Private

    private var soundingHoles: Set<Hole> {
        Set(soundingReeds.map(\.hole))
    }

    private func intensityOf(_ positions: [PositionOnHarmonica]) -> BreathIntensity? {
        PositionOnHarmonica.topmost(of: positions).map(BreathIntensity.init(at:))
    }

    private func applyBreathIntensity(_ intensity: BreathIntensity) {
        guard intensity != soundingIntensity else { return }

        audioEngine.changeIntensity(to: intensity)
        soundingIntensity = intensity
    }

    private func reedsUnder(_ positions: [PositionOnHarmonica]) -> [Reed] {
        guard let breath = Breath(topmostOf: positions) else { return [] }

        return holesUnder(positions).map { Reed(hole: $0, breath: breath) }
    }

    private func holesUnder(_ positions: [PositionOnHarmonica]) -> [Hole] {
        Set(positions.compactMap(Hole.init(at:))).sorted { $0.number < $1.number }
    }

    private func sound(_ reeds: [Reed]) {
        audioEngine.soundTones(reeds.map { tuning.tone(for: $0, in: key) })
        soundingReeds = reeds
    }
}
