#if arch(wasm32)
import HarmonicaCore

struct ReedDTO: Encodable {
    let hole: Int
    let breath: String
    let bendableSemitones: Double
    let overbendableSemitones: Double

    init(hole: Hole, breath: Breath, tuning: RichterTuning) {
        self.hole = hole.number
        self.breath = breath == .blow ? "blow" : "draw"
        bendableSemitones = tuning.bendableSemitones(for: Reed(hole: hole, breath: breath))
        overbendableSemitones = tuning.overbendableSemitones(for: Reed(hole: hole, breath: breath))
    }
}
#endif
