import type { Hole } from '../instrument/hole.js'
import type { ScoreEvent, ScoreNote } from './score.js'

export interface Expression {
    readonly bentBy?: number
    readonly releasingTo?: number
    readonly vibrato?: number
    readonly slideFrom?: Hole
    readonly shakenWith?: Hole
}

export function blow(holes: Hole | readonly Hole[], beats: number, expression: Expression = {}): ScoreEvent {
    return played(holes, 'blow', beats, expression)
}

export function draw(holes: Hole | readonly Hole[], beats: number, expression: Expression = {}): ScoreEvent {
    return played(holes, 'draw', beats, expression)
}

export function overblow(hole: Hole, beats: number): ScoreEvent {
    return { kind: 'note', note: { holes: [hole], breath: 'blow', beats, isOverbent: true } }
}

export function rest(beats: number): ScoreEvent {
    return { kind: 'rest', beats }
}

function played(
    holes: Hole | readonly Hole[],
    breath: 'blow' | 'draw',
    beats: number,
    expression: Expression
): ScoreEvent {
    const note: ScoreNote = {
        holes: Array.isArray(holes) ? holes : [holes as Hole],
        breath,
        beats,
        bentBySemitones: expression.bentBy ?? 0,
        vibrato: expression.vibrato ?? 0,
        ...(expression.slideFrom === undefined ? {} : { slideFrom: expression.slideFrom }),
        ...(expression.shakenWith === undefined ? {} : { shakenWith: expression.shakenWith }),
        ...(expression.releasingTo === undefined ? {} : { bendEndsAtSemitones: expression.releasingTo })
    }
    return { kind: 'note', note }
}
