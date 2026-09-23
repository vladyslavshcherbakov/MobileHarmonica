import HarmonicaCore
import HarmonicaCoreTestSupport
@testable import MobileHarmonica

@MainActor
final class OfflineSamplerEngine: AudioEngineProtocol {
    private let controls: ReedSamplerControls

    let sampler: ReedSampler

    // MARK: - Public

    nonisolated init() {
        let sampler = ReedSampler(samples: SineSamples.bank(), log: RecordingLog())
        self.sampler = sampler
        controls = ReedSamplerControls(sampler: sampler)
    }

    func prepare() async throws(AudioEngineError) {}

    func soundTones(_ tones: [Tone], as change: ToneChange) {
        controls.soundTones(tones, as: change)
    }

    func changeIntensity(to intensity: BreathIntensity) {
        controls.changeIntensity(to: intensity)
    }

    func changeBend(to depth: BendDepth) {
        controls.changeBend(to: depth)
    }

    func changeVibrato(to depth: VibratoDepth) {
        controls.changeVibrato(to: depth)
    }

    func cupHands(to depth: CupDepth) {
        controls.cupHands(to: depth)
    }

    func silence(_ release: ReedRelease) {
        controls.silence(release)
    }
}
