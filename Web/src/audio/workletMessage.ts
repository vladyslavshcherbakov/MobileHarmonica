import type { RecordedNote } from './sampleBank.js'

export const processorName = 'harmonica'

export interface SoundingTone {
    readonly hertz: number
    readonly bendableSemitones: number
}

export type WorkletMessage =
    | {
        readonly kind: 'samples'
        readonly frames: Float32Array
        readonly notes: readonly RecordedNote[]
    }
    | {
        readonly kind: 'sound'
        readonly tones: readonly SoundingTone[]
        readonly crossfadeSeconds: number
        readonly everyReedSpeaksAgain: boolean
    }
    | { readonly kind: 'breathGain'; readonly value: number }
    | { readonly kind: 'bend'; readonly value: number }
    | { readonly kind: 'vibrato'; readonly value: number }
    | { readonly kind: 'cup'; readonly value: number }
    | { readonly kind: 'ringDown' }
    | { readonly kind: 'damp'; readonly seconds: number }
