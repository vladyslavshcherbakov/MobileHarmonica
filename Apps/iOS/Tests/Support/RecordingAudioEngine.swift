@testable import MobileHarmonica

final class RecordingAudioEngine: AudioEngineProtocol {
    private(set) var soundedTones: [[Tone]] = []
    private(set) var toneChanges: [ToneChange] = []
    private(set) var intensities: [BreathIntensity] = []
    private(set) var bends: [BendDepth] = []
    private(set) var vibratos: [VibratoDepth] = []
    private(set) var silencings = 0

    func prepare() async throws {}

    func soundTones(_ tones: [Tone], as change: ToneChange) {
        soundedTones.append(tones)
        toneChanges.append(change)
    }

    func changeIntensity(to intensity: BreathIntensity) {
        intensities.append(intensity)
    }

    func changeBend(to depth: BendDepth) {
        bends.append(depth)
    }

    func changeVibrato(to depth: VibratoDepth) {
        vibratos.append(depth)
    }

    func silence() {
        silencings += 1
    }
}
