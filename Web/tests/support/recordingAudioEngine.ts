import type { AudioEngine } from '../../src/domain/protocols/audioEngine.js'
import type { Tone } from '../../src/domain/instrument/tone.js'
import type { ToneChange } from '../../src/domain/playing/toneChange.js'
import type { ReedRelease } from '../../src/domain/playing/reedRelease.js'
import type { BreathIntensity } from '../../src/domain/playing/breathIntensity.js'
import type { BendDepth } from '../../src/domain/playing/bendDepth.js'
import type { VibratoDepth } from '../../src/domain/playing/vibratoDepth.js'
import type { CupDepth } from '../../src/domain/playing/cupDepth.js'

export class RecordingAudioEngine implements AudioEngine {
    readonly soundedTones: (readonly Tone[])[] = []
    readonly toneChanges: ToneChange[] = []
    readonly intensities: BreathIntensity[] = []
    readonly bends: BendDepth[] = []
    readonly vibratos: VibratoDepth[] = []
    readonly cups: CupDepth[] = []
    readonly releases: ReedRelease[] = []

    get silencings(): number {
        return this.releases.length
    }

    get hertzOfTheFirstTone(): number {
        return this.soundedTones[0]?.[0]?.hertz ?? 0
    }

    get hertzOfTheLastTone(): number {
        return this.soundedTones[this.soundedTones.length - 1]?.[0]?.hertz ?? 0
    }

    get hertzOfEveryTone(): number[] {
        return this.soundedTones.map(tones => Math.round(tones[0]?.hertz ?? 0))
    }

    async prepare(): Promise<void> {}

    soundTones(tones: readonly Tone[], change: ToneChange): void {
        this.soundedTones.push(tones)
        this.toneChanges.push(change)
    }

    changeIntensity(intensity: BreathIntensity): void {
        this.intensities.push(intensity)
    }

    changeBend(depth: BendDepth): void {
        this.bends.push(depth)
    }

    changeVibrato(depth: VibratoDepth): void {
        this.vibratos.push(depth)
    }

    cupHands(depth: CupDepth): void {
        this.cups.push(depth)
    }

    silence(release: ReedRelease): void {
        this.releases.push(release)
    }
}
