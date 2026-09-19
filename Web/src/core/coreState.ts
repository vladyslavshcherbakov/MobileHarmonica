export interface CoreSoundingHole {
    readonly hole: number
    readonly breath: 'blow' | 'draw'
    readonly pitch: number
    readonly unbent: number
    readonly isShifted: boolean
    readonly isOverbent: boolean
}

export interface CoreState {
    readonly keyPosition: number
    readonly style: string
    readonly mouthHolesWide: number
    readonly cup: number
    readonly canBend: boolean
    readonly canOverbend: boolean
    readonly breath: 'blow' | 'draw' | null
    readonly sounding: readonly CoreSoundingHole[]
}

export interface CoreEvent {
    readonly holes: readonly number[]
    readonly breath: 'blow' | 'draw' | null
    readonly beats: number
    readonly bentBySemitones: number
    readonly isOverbent: boolean
    readonly vibrato: number
    readonly slideFrom: number | null
    readonly shakenWith: number | null
    readonly bendEndsAtSemitones: number | null
}

export interface CoreTune {
    readonly name: string
    readonly keyPosition: number
    readonly position: 'first' | 'second' | 'third'
    readonly beatsPerMinute: number
    readonly events: readonly CoreEvent[]
}

export interface CoreTone {
    readonly hertz: number
    readonly bendableSemitones: number
}

export type CoreToneChange = 'slide' | 'newReed' | 'breathReversed'

export interface CoreAudio {
    soundTones(tones: readonly CoreTone[], change: CoreToneChange): void
    changeIntensity(gain: number): void
    changeBend(fraction: number): void
    changeVibrato(fraction: number): void
    cupHands(fraction: number): void
    silence(ringsDown: boolean): void
}

export interface CoreFinger {
    readonly fractionFromLeftEdge: number
    readonly fractionAboveCentreLine: number
    readonly fractionCoveredEitherSide: number
}
