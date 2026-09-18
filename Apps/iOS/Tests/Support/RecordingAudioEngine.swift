@testable import MobileHarmonica

final class RecordingAudioEngine: AudioEngineProtocol {
    private(set) var soundedTones: [[Tone]] = []
    private(set) var intensities: [BreathIntensity] = []
    private(set) var bends: [BendDepth] = []
    private(set) var overbends: [OverbendDepth] = []
    private(set) var vibratos: [VibratoDepth] = []
    private(set) var silencings = 0

    func prepare() async throws {}

    func soundTones(_ tones: [Tone]) {
        soundedTones.append(tones)
    }

    func changeIntensity(to intensity: BreathIntensity) {
        intensities.append(intensity)
    }

    func changeBend(to depth: BendDepth) {
        bends.append(depth)
    }

    func changeOverbend(to depth: OverbendDepth) {
        overbends.append(depth)
    }

    func changeVibrato(to depth: VibratoDepth) {
        vibratos.append(depth)
    }

    func silence() {
        silencings += 1
    }
}
