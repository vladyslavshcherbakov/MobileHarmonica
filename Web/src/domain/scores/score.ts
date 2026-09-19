import type { Breath } from '../instrument/breath.js'
import type { Hole } from '../instrument/hole.js'
import type { HarmonicaKey } from '../instrument/harmonicaKey.js'
import { keyTransposedBy, semitonesFromC } from '../instrument/harmonicaKey.js'
import type { HarmonicaPosition } from '../instrument/harmonicaPosition.js'
import { semitonesAboveTheHarmonica } from '../instrument/harmonicaPosition.js'

export interface ScoreNote {
    readonly holes: readonly Hole[]
    readonly breath: Breath
    readonly beats: number
    readonly bentBySemitones?: number
    readonly isOverbent?: boolean
    readonly vibrato?: number
    readonly slideFrom?: Hole
    readonly shakenWith?: Hole
    readonly bendEndsAtSemitones?: number
}

export type ScoreEvent =
    | { readonly kind: 'note'; readonly note: ScoreNote }
    | { readonly kind: 'rest'; readonly beats: number }

export interface Score {
    readonly name: string
    readonly key: HarmonicaKey
    readonly position: HarmonicaPosition
    readonly beatsPerMinute: number
    readonly events: readonly ScoreEvent[]
}

export function beatsOf(event: ScoreEvent): number {
    return event.kind === 'note' ? event.note.beats : event.beats
}

export function harmonicaKeyOf(score: Score): HarmonicaKey {
    return keyTransposedBy(semitonesFromC(score.key) - semitonesAboveTheHarmonica(score.position))
}

export function secondsPerBeat(score: Score): number {
    return 60 / score.beatsPerMinute
}
