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

// MARK: - Reading back the pitch

extension RecordingAudioEngine {
    var hertzOfTheFirstTone: Double {
        hertz(of: soundedTones.first)
    }

    var hertzOfTheLastTone: Double {
        hertz(of: soundedTones.last)
    }

    private func hertz(of tones: [Tone]?) -> Double {
        tones?.first?.pitch.converted(to: .hertz).value ?? 0
    }
}
