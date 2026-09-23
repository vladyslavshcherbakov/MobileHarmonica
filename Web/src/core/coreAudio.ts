export interface CoreAudio {
    soundTones(tones: readonly CoreTone[], change: CoreToneChange): void
    changeIntensity(gain: number): void
    changeBend(fraction: number): void
    changeVibrato(fraction: number): void
    cupHands(fraction: number): void
    silence(ringsDown: boolean): void
}

export interface CoreTone {
    readonly hertz: number
    readonly bendableSemitones: number
}

export type CoreToneChange = 'slide' | 'newReed' | 'breathReversed'
