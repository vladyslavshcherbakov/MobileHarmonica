import type { Harmonica } from '../instrument/harmonica.js'
import type { Hole } from '../instrument/hole.js'
import { holes as everyHole } from '../instrument/hole.js'
import { bendableSemitones } from '../instrument/richterTuning.js'
import type { PitchShaping } from '../playing/pitchShaping.js'
import { pitchShaping, restingShaping } from '../playing/pitchShaping.js'
import { vibratoDepth, vibratoOff } from '../playing/vibratoDepth.js'
import type { Log } from '../protocols/log.js'
import type { Score, ScoreEvent, ScoreNote } from '../scores/score.js'
import { harmonicaKeyOf, secondsPerBeat } from '../scores/score.js'
import type { PlayHarmonica } from './playHarmonica.js'

const articulationSeconds = 0.05
const slideStepSeconds = 0.04
const shakeStepSeconds = 0.06
const bendStepSeconds = 0.01

export interface ScorePerformance {
    readonly finished: Promise<void>
    cancel(): void
}

interface Cancellation {
    stopped: boolean
}

export class PlayScore {
    constructor(
        private readonly harmonica: PlayHarmonica,
        private readonly log: Log
    ) {}

    play(score: Score, played: (harmonica: Harmonica) => void): ScorePerformance {
        const cancellation: Cancellation = { stopped: false }
        const finished = this.perform(score, played, cancellation)
        return { finished, cancel: () => { cancellation.stopped = true } }
    }

    private async perform(
        score: Score,
        played: (harmonica: Harmonica) => void,
        cancellation: Cancellation
    ): Promise<void> {
        this.log.record(
            `score started in ${score.key}, ${score.position} position,`
            + ` calling for a harmonica in ${harmonicaKeyOf(score)}`
        )
        played(this.harmonica.changeKey(harmonicaKeyOf(score)))
        for (const event of score.events) {
            if (cancellation.stopped) break

            await this.performEvent(event, secondsPerBeat(score), played, cancellation)
        }
        played(this.harmonica.shapeTone(restingShaping, vibratoOff))
        played(this.harmonica.stopPlaying('ringsDown'))
        this.log.record(cancellation.stopped ? 'score stopped early' : 'score finished')
    }

    private async performEvent(
        event: ScoreEvent,
        secondsPerBeat: number,
        played: (harmonica: Harmonica) => void,
        cancellation: Cancellation
    ): Promise<void> {
        const seconds = (event.kind === 'note' ? event.note.beats : event.beats) * secondsPerBeat
        if (event.kind === 'rest') return wait(seconds)

        const slid = await this.slide(event.note, seconds, played, cancellation)
        await this.sound(event.note, seconds - slid, played, cancellation)
    }

    private async slide(
        note: ScoreNote,
        seconds: number,
        played: (harmonica: Harmonica) => void,
        cancellation: Cancellation
    ): Promise<number> {
        const passing = passingHoles(note)
        if (passing.length === 0) return 0

        const step = Math.min(slideStepSeconds, seconds / 2 / passing.length)
        played(this.harmonica.shapeTone(restingShaping, vibratoOff))
        for (const hole of passing) {
            if (cancellation.stopped) break

            played(this.harmonica.play([hole], note.breath))
            await wait(step)
        }
        return step * passing.length
    }

    private async sound(
        note: ScoreNote,
        seconds: number,
        played: (harmonica: Harmonica) => void,
        cancellation: Cancellation
    ): Promise<void> {
        const gap = Math.min(articulationSeconds, seconds / 4)
        const sounding = seconds - gap
        const steps = stepsOf(note, sounding)
        const started = now()
        for (let step = 0; step < steps; step += 1) {
            if (cancellation.stopped) break

            this.harmonica.shapeTone(
                this.shapingFor(note, fractionOf(step, steps)),
                vibratoDepth(note.vibrato ?? 0)
            )
            played(this.harmonica.play(holesOf(note, step), note.breath))
            await waitUntil(started + (sounding * (step + 1)) / steps)
        }
        played(this.harmonica.stopPlaying('damped'))
        await wait(gap)
    }

    private shapingFor(note: ScoreNote, fraction: number): PitchShaping {
        if (note.isOverbent === true) return pitchShaping(1)

        const semitones = bendOf(note, fraction)
        const range = Math.max(
            0,
            ...note.holes.map(hole => bendableSemitones({ hole, breath: note.breath }))
        )
        if (semitones <= 0 || range <= 0) return restingShaping

        return pitchShaping(-semitones / range)
    }
}

function stepsOf(note: ScoreNote, seconds: number): number {
    const step = stepSecondsOf(note)
    if (step === null) return 1

    return Math.max(1, Math.floor(seconds / step))
}

function stepSecondsOf(note: ScoreNote): number | null {
    if (note.shakenWith !== undefined) return shakeStepSeconds

    return note.bendEndsAtSemitones === undefined ? null : bendStepSeconds
}

function fractionOf(step: number, steps: number): number {
    return steps > 1 ? step / (steps - 1) : 0
}

function bendOf(note: ScoreNote, fraction: number): number {
    const bent = note.bentBySemitones ?? 0
    const ending = note.bendEndsAtSemitones
    if (ending === undefined) return bent

    return bent + (ending - bent) * fraction
}

function passingHoles(note: ScoreNote): Hole[] {
    const from = note.slideFrom
    const arriving = note.holes[0]
    if (from === undefined || arriving === undefined || from === arriving) return []

    const numbers = from < arriving
        ? everyHole.filter(hole => hole >= from && hole < arriving)
        : everyHole.filter(hole => hole > arriving && hole <= from).reverse()
    return numbers
}

function holesOf(note: ScoreNote, step: number): readonly Hole[] {
    const shaken = note.shakenWith
    if (shaken === undefined || step % 2 === 0) return note.holes

    return [shaken]
}

function now(): number {
    return performance.now() / 1000
}

function wait(seconds: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, Math.max(0, seconds) * 1000))
}

function waitUntil(seconds: number): Promise<void> {
    return wait(seconds - now())
}
