import type { Tone } from '../instrument/tone.js'
import type { ToneChange } from '../playing/toneChange.js'
import type { ReedRelease } from '../playing/reedRelease.js'
import type { BreathIntensity } from '../playing/breathIntensity.js'
import type { BendDepth } from '../playing/bendDepth.js'
import type { VibratoDepth } from '../playing/vibratoDepth.js'
import type { CupDepth } from '../playing/cupDepth.js'

export interface AudioEngine {
    prepare(): Promise<void>
    soundTones(tones: readonly Tone[], change: ToneChange): void
    changeIntensity(intensity: BreathIntensity): void
    changeBend(depth: BendDepth): void
    changeVibrato(depth: VibratoDepth): void
    cupHands(depth: CupDepth): void
    silence(release: ReedRelease): void
}
