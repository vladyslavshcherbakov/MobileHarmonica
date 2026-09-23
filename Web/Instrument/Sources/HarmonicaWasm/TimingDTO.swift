#if arch(wasm32)
import HarmonicaCore

struct TimingDTO: Encodable {
    let articulationSeconds = ScoreTiming.articulationSeconds
    let slideStepSeconds = ScoreTiming.slideStepSeconds
    let shakeStepSeconds = ScoreTiming.shakeStepSeconds
    let bendStepSeconds = ScoreTiming.bendStepSeconds
}
#endif
