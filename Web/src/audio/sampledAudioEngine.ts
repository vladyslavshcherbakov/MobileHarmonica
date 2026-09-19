import type { AudioEngine } from '../domain/protocols/audioEngine.js'
import type { Log } from '../domain/protocols/log.js'
import type { Tone } from '../domain/instrument/tone.js'
import type { ToneChange } from '../domain/playing/toneChange.js'
import type { ReedRelease } from '../domain/playing/reedRelease.js'
import type { BreathIntensity } from '../domain/playing/breathIntensity.js'
import type { BendDepth } from '../domain/playing/bendDepth.js'
import type { VibratoDepth } from '../domain/playing/vibratoDepth.js'
import type { CupDepth } from '../domain/playing/cupDepth.js'
import type { WorkletMessage, WorkletReport } from './workletMessage.js'
import { processorName } from './workletMessage.js'
import { recordedHarmonica } from './recordedHarmonica.js'

const amplitude = 0.25
const slideCrossfadeSeconds = 0.02
const newReedCrossfadeSeconds = 0.05
const reedStopsInSeconds = 0.02

export class SampledAudioEngine implements AudioEngine {
    private context: AudioContext | null = null
    private node: AudioWorkletNode | null = null
    private askedToSoundAt = 0

    constructor(
        private readonly workletUrl: string,
        private readonly samplesFolder: string,
        private readonly log: Log
    ) {}

    async prepare(): Promise<void> {
        try {
            await this.build()
        } catch (failure) {
            this.log.record(`audio failed to prepare: ${describe(failure)}`)
            throw failure
        }
    }

    soundTones(tones: readonly Tone[], change: ToneChange): void {
        this.askedToSoundAt = this.context?.currentTime ?? 0
        this.send({
            kind: 'sound',
            tones: tones.map(tone => ({ hertz: tone.hertz, bendableSemitones: tone.bendableSemitones })),
            crossfadeSeconds: crossfadeSecondsFor(change),
            everyReedSpeaksAgain: change === 'breathReversed'
        })
    }

    changeIntensity(intensity: BreathIntensity): void {
        this.send({ kind: 'breathGain', value: intensity })
    }

    changeBend(depth: BendDepth): void {
        this.send({ kind: 'bend', value: depth })
    }

    changeVibrato(depth: VibratoDepth): void {
        this.send({ kind: 'vibrato', value: depth })
    }

    cupHands(depth: CupDepth): void {
        this.send({ kind: 'cup', value: depth })
    }

    silence(release: ReedRelease): void {
        this.send(release === 'ringsDown' ? { kind: 'ringDown' } : { kind: 'damp', seconds: reedStopsInSeconds })
    }

    private async build(): Promise<void> {
        if (this.node !== null) {
            this.log.record('audio was already built, resuming it')
            return this.resume()
        }

        playOverTheSilentSwitch()
        this.log.record('audio session asked to play over the silent switch')
        const context = new AudioContext({ latencyHint: 'interactive' })
        this.context = context
        this.log.record(
            `audio context created at ${context.sampleRate} Hz,`
            + ` ${milliseconds(context.baseLatency)} ms of buffer`
            + ` and ${milliseconds(context.outputLatency)} ms out to the speaker,`
            + ` state ${context.state}`
        )
        await this.connect(context)
        await this.resume()
        this.log.record(`audio context is ${context.state}`)
        await this.loadTheRecordings(context)
    }

    private async connect(context: AudioContext): Promise<void> {
        this.log.record(`loading the worklet from ${this.workletUrl}`)
        await context.audioWorklet.addModule(this.workletUrl)
        this.log.record('worklet loaded')
        const node = new AudioWorkletNode(context, processorName, {
            numberOfInputs: 0,
            numberOfOutputs: 1,
            outputChannelCount: [1],
            processorOptions: { amplitude }
        })
        node.connect(context.destination)
        node.port.onmessage = event => this.readTheReport(event.data as WorkletReport)
        this.node = node
        this.log.record('worklet connected to the speaker')
    }

    private async loadTheRecordings(context: AudioContext): Promise<void> {
        this.log.record(`reading the recordings from ${this.samplesFolder}`)
        const samples = await recordedHarmonica(this.samplesFolder, context, this.log)
        this.node?.port.postMessage(
            { kind: 'samples', frames: samples.frames, notes: samples.notes },
            [samples.frames.buffer]
        )
        this.log.record(`loaded ${samples.notes.length} recorded notes`)
    }

    private readTheReport(report: WorkletReport): void {
        const since = (report.at - this.askedToSoundAt) * 1000
        this.log.recordSample(
            report.kind === 'took'
                ? `the worklet took the reeds ${since.toFixed(1)} ms after they were asked for`
                : `the first sample left ${since.toFixed(1)} ms after they were asked for`
        )
    }

    private async resume(): Promise<void> {
        if (this.context?.state !== 'suspended') return

        this.log.record('audio context is suspended, resuming it')
        await this.context.resume()
    }

    private send(message: WorkletMessage): void {
        this.node?.port.postMessage(message)
    }
}

function describe(failure: unknown): string {
    return failure instanceof Error ? `${failure.name}: ${failure.message}` : String(failure)
}

function milliseconds(seconds: number): string {
    return Number.isFinite(seconds) ? (seconds * 1000).toFixed(1) : 'unreported'
}

function crossfadeSecondsFor(change: ToneChange): number {
    return change === 'newReed' ? newReedCrossfadeSeconds : slideCrossfadeSeconds
}

function playOverTheSilentSwitch(): void {
    const session = (navigator as NavigatorWithAudioSession).audioSession
    if (session === undefined) return

    session.type = 'playback'
}

interface NavigatorWithAudioSession {
    audioSession?: { type: string }
}
