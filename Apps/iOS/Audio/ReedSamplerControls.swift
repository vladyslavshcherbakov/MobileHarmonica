import Foundation
import HarmonicaCore

struct ReedSamplerControls {
    private static let slideCrossfadeSeconds = 0.02
    private static let newReedCrossfadeSeconds = 0.05

    let sampler: ReedSampler

    // MARK: - Public

    func soundTones(_ tones: [Tone], as change: ToneChange) {
        sampler.sound(
            tones.map(Self.sounding),
            over: Self.crossfadeSeconds(for: change),
            everyReedSpeaksAgain: change == .breathReversed
        )
    }

    func changeIntensity(to intensity: BreathIntensity) {
        sampler.changeBreathGain(to: intensity.gain)
    }

    func changeBend(to depth: BendDepth) {
        sampler.changeBend(to: depth.fraction)
    }

    func changeVibrato(to depth: VibratoDepth) {
        sampler.changeVibrato(to: depth.fraction)
    }

    func cupHands(to depth: CupDepth) {
        sampler.cupHands(to: depth.fraction)
    }

    func silence(_ release: ReedRelease) {
        switch release {
        case .ringsDown: sampler.ringDown()
        case .damped: sampler.damp()
        }
    }

    // MARK: - Private

    private static func crossfadeSeconds(for change: ToneChange) -> Double {
        switch change {
        case .slide, .breathReversed: slideCrossfadeSeconds
        case .newReed: newReedCrossfadeSeconds
        }
    }

    private static func sounding(_ tone: Tone) -> SoundingTone {
        SoundingTone(
            hertz: tone.pitch.converted(to: .hertz).value,
            bendableSemitones: tone.bendableSemitones
        )
    }
}
