import Foundation

final class PlayHarmonica {
    private let tuning: RichterTuning
    private let audioEngine: AudioEngineProtocol
    private let log: LogProtocol
    private var soundingReeds: [Reed] = []
    private var soundingIntensity: BreathIntensity?
    private var bend: BendDepth = .unbent
    private var vibrato: VibratoDepth = .off

    private(set) var key: HarmonicaKey = .c

    // MARK: - Public

    init(tuning: RichterTuning, audioEngine: AudioEngineProtocol, log: LogProtocol) {
        self.tuning = tuning
        self.audioEngine = audioEngine
        self.log = log
    }

    func prepare() async throws {
        try await audioEngine.prepare()
        log.record("harmonica ready in key \(key)")
    }

    func play(at positions: [PositionOnHarmonica]) -> Set<Hole> {
        let sounding = positions.filter(\.isOnTheHarmonica)
        let reeds = reedsUnder(sounding)
        guard !reeds.isEmpty, let intensity = intensityOf(sounding) else {
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
        log.record("key changed to \(key), \(key.semitonesFromC) semitones from C")
        guard !soundingReeds.isEmpty else { return [] }

        sound(soundingReeds)
        return soundingHoles
    }

    func shapeTone(bend: BendDepth, vibrato: VibratoDepth) {
        guard bend != self.bend || vibrato != self.vibrato else { return }

        self.bend = bend
        self.vibrato = vibrato
        log.recordSample("bend \(rounded(bend.fraction)) of \(rounded(bendableSemitones)) semitones, vibrato \(rounded(vibrato.fraction))")
        audioEngine.changeBend(to: bend)
        audioEngine.changeVibrato(to: vibrato)
    }

    func stopPlaying() {
        guard !soundingReeds.isEmpty else { return }

        audioEngine.silence()
        log.record("silent, \(describe(soundingReeds)) released")
        soundingReeds = []
        soundingIntensity = nil
    }

    // MARK: - Private

    private var soundingHoles: Set<Hole> {
        Set(soundingReeds.map(\.hole))
    }

    var bendableSemitones: Double {
        soundingReeds.map { tuning.tone(for: $0, in: key).bendableSemitones }.max() ?? 0
    }

    private func intensityOf(_ positions: [PositionOnHarmonica]) -> BreathIntensity? {
        PositionOnHarmonica.topmost(of: positions).map(BreathIntensity.init(at:))
    }

    private func applyBreathIntensity(_ intensity: BreathIntensity) {
        guard intensity != soundingIntensity else { return }

        audioEngine.changeIntensity(to: intensity)
        soundingIntensity = intensity
        log.recordSample("breath intensity \(rounded(intensity.gain))")
    }

    private func reedsUnder(_ positions: [PositionOnHarmonica]) -> [Reed] {
        guard let breath = Breath(topmostOf: positions) else { return [] }

        return holesUnder(positions).map { Reed(hole: $0, breath: breath) }
    }

    private func holesUnder(_ positions: [PositionOnHarmonica]) -> [Hole] {
        Set(positions.compactMap(Hole.init(at:))).sorted { $0.number < $1.number }
    }

    private func sound(_ reeds: [Reed]) {
        let tones = reeds.map { tuning.tone(for: $0, in: key) }
        audioEngine.soundTones(tones)
        soundingReeds = reeds
        log.record("sounding \(describe(reeds)) in key \(key)")
    }

    private func describe(_ reeds: [Reed]) -> String {
        reeds
            .map { "hole \($0.hole.number) \($0.breath) \(rounded(tuning.tone(for: $0, in: key).pitch.converted(to: .hertz).value)) Hz" }
            .joined(separator: ", ")
    }

    private func rounded(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
