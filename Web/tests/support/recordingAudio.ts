import type { AudioEngine, AudioEngineFailure } from '../../src/core/audioEngine.js'
import type { CoreTone, CoreToneChange } from '../../src/core/coreAudio.js'

export class RecordingAudio implements AudioEngine {
    readonly soundedTones: (readonly CoreTone[])[] = []
    readonly releases: ('ringsDown' | 'damped')[] = []
    preparationFailure: AudioEngineFailure | null = null

    async prepare(): Promise<void> {
        if (this.preparationFailure !== null) throw this.preparationFailure
    }

    soundTones(tones: readonly CoreTone[], _change: CoreToneChange): void {
        this.soundedTones.push(tones)
    }

    changeIntensity(): void {}

    changeBend(): void {}

    changeVibrato(): void {}

    cupHands(): void {}

    silence(ringsDown: boolean): void {
        this.releases.push(ringsDown ? 'ringsDown' : 'damped')
    }

    get hertzOfTheLastTone(): number {
        return this.soundedTones[this.soundedTones.length - 1]?.[0]?.hertz ?? 0
    }
}
