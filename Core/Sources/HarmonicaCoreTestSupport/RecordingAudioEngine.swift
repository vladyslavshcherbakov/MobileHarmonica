import HarmonicaCore

public final class RecordingAudioEngine: AudioEngineProtocol {
    public private(set) var soundedTones: [[Tone]] = []
    public private(set) var toneChanges: [ToneChange] = []
    public private(set) var intensities: [BreathIntensity] = []
    public private(set) var bends: [BendDepth] = []
    public private(set) var vibratos: [VibratoDepth] = []
    public private(set) var cups: [CupDepth] = []
    public private(set) var releases: [ReedRelease] = []

    public init() {}

    public var silencings: Int {
        releases.count
    }

    public func prepare() async throws {}

    public func soundTones(_ tones: [Tone], as change: ToneChange) {
        soundedTones.append(tones)
        toneChanges.append(change)
    }

    public func changeIntensity(to intensity: BreathIntensity) {
        intensities.append(intensity)
    }

    public func changeBend(to depth: BendDepth) {
        bends.append(depth)
    }

    public func changeVibrato(to depth: VibratoDepth) {
        vibratos.append(depth)
    }

    public func cupHands(to depth: CupDepth) {
        cups.append(depth)
    }

    public func silence(_ release: ReedRelease) {
        releases.append(release)
    }
}

// MARK: - Reading back the pitch

extension RecordingAudioEngine {
    public var hertzOfTheFirstTone: Double {
        hertz(of: soundedTones.first)
    }

    public var hertzOfTheLastTone: Double {
        hertz(of: soundedTones.last)
    }

    private func hertz(of tones: [Tone]?) -> Double {
        tones?.first?.pitch.converted(to: .hertz).value ?? 0
    }
}
