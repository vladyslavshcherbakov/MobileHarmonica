import type { CoreEvent, CoreReed, CoreState, CoreTiming, CoreTune } from '../../core/coreState.js'
import type { HarmonicaCore } from '../../core/harmonicaCore.js'

export type TuneEnding = 'played' | 'stopped'

export interface TunePerformance {
    readonly finished: Promise<TuneEnding>
    cancel(): void
}

interface Cancellation {
    stopped: boolean
}

export class PlayTheTune {
    constructor(
        private readonly core: HarmonicaCore,
        private readonly tunes: readonly CoreTune[],
        private readonly reeds: readonly CoreReed[],
        private readonly timing: CoreTiming
    ) {}

    play(index: number, played: (harmonica: CoreState) => void): TunePerformance {
        const cancellation: Cancellation = { stopped: false }
        const tune = this.tunes[index]
        const finished: Promise<TuneEnding> = tune === undefined
            ? Promise.resolve('played')
            : this.perform(tune, played, cancellation)
        return { finished, cancel: () => { cancellation.stopped = true } }
    }

    private async perform(
        tune: CoreTune,
        played: (harmonica: CoreState) => void,
        cancellation: Cancellation
    ): Promise<TuneEnding> {
        played(this.core.changeKey(tune.harmonicaKeyPosition))
        const secondsPerBeat = 60 / tune.beatsPerMinute
        for (const event of tune.events) {
            if (cancellation.stopped) break

            await this.performEvent(event, secondsPerBeat, played, cancellation)
        }
        if (cancellation.stopped) return 'stopped'

        played(this.core.shapeTone(0, 0))
        played(this.core.stopPlaying(true))
        return 'played'
    }

    private async performEvent(
        event: CoreEvent,
        secondsPerBeat: number,
        played: (harmonica: CoreState) => void,
        cancellation: Cancellation
    ): Promise<void> {
        const seconds = event.beats * secondsPerBeat
        if (event.breath === null || event.holes.length === 0) return wait(seconds)

        const slid = await this.slide(event, seconds, played, cancellation)
        await this.sound(event, seconds - slid, played, cancellation)
    }

    private async slide(
        note: CoreEvent,
        seconds: number,
        played: (harmonica: CoreState) => void,
        cancellation: Cancellation
    ): Promise<number> {
        const passing = passingHoles(note)
        if (passing.length === 0) return 0

        const step = Math.min(this.timing.slideStepSeconds, seconds / 2 / passing.length)
        played(this.core.shapeTone(0, 0))
        for (const hole of passing) {
            if (cancellation.stopped) break

            played(this.core.play([hole], note.breath ?? 'blow'))
            await wait(step)
        }
        return step * passing.length
    }

    private async sound(
        note: CoreEvent,
        seconds: number,
        played: (harmonica: CoreState) => void,
        cancellation: Cancellation
    ): Promise<void> {
        const gap = Math.min(this.timing.articulationSeconds, seconds / 4)
        const sounding = seconds - gap
        const steps = this.stepsOf(note, sounding)
        const started = now()
        for (let step = 0; step < steps; step += 1) {
            if (cancellation.stopped) break

            this.core.shapeTone(this.shapingFor(note, fractionOf(step, steps)), note.vibrato)
            played(this.core.play(holesOf(note, step), note.breath ?? 'blow'))
            await waitUntil(started + (sounding * (step + 1)) / steps)
        }
        if (cancellation.stopped) return

        played(this.core.stopPlaying(false))
        await wait(gap)
    }

    private shapingFor(note: CoreEvent, fraction: number): number {
        if (note.isOverbent) return 1

        const semitones = bendOf(note, fraction)
        const range = this.bendableSemitones(note)
        if (semitones <= 0 || range <= 0) return 0

        return -semitones / range
    }

    private stepsOf(note: CoreEvent, seconds: number): number {
        const step = this.stepSecondsOf(note)
        if (step === null) return 1

        return Math.max(1, Math.floor(seconds / step))
    }

    private stepSecondsOf(note: CoreEvent): number | null {
        if (note.shakenWith !== null) return this.timing.shakeStepSeconds

        return note.bendEndsAtSemitones === null ? null : this.timing.bendStepSeconds
    }

    private bendableSemitones(note: CoreEvent): number {
        const ranges = note.holes.map(hole =>
            this.reeds.find(reed => reed.hole === hole && reed.breath === note.breath)?.bendableSemitones ?? 0
        )
        return Math.max(0, ...ranges)
    }
}

function fractionOf(step: number, steps: number): number {
    return steps > 1 ? step / (steps - 1) : 0
}

function bendOf(note: CoreEvent, fraction: number): number {
    const ending = note.bendEndsAtSemitones
    if (ending === null) return note.bentBySemitones

    return note.bentBySemitones + (ending - note.bentBySemitones) * fraction
}

function passingHoles(note: CoreEvent): number[] {
    const from = note.slideFrom
    const arriving = note.holes[0]
    if (from === null || arriving === undefined || from === arriving) return []

    const holes: number[] = []
    if (from < arriving) {
        for (let hole = from; hole < arriving; hole += 1) holes.push(hole)
    } else {
        for (let hole = from; hole > arriving; hole -= 1) holes.push(hole)
    }
    return holes
}

function holesOf(note: CoreEvent, step: number): number[] {
    const shaken = note.shakenWith
    if (shaken === null || step % 2 === 0) return [...note.holes]

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
