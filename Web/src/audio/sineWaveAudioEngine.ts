import type { AudioEngine } from '../domain/protocols/audioEngine.js'
import type { Log } from '../domain/protocols/log.js'
import type { Tone } from '../domain/instrument/tone.js'
import type { ToneChange } from '../domain/playing/toneChange.js'
import type { ReedRelease } from '../domain/playing/reedRelease.js'
import type { BreathIntensity } from '../domain/playing/breathIntensity.js'
import type { BendDepth } from '../domain/playing/bendDepth.js'
import type { VibratoDepth } from '../domain/playing/vibratoDepth.js'
import type { CupDepth } from '../domain/playing/cupDepth.js'
import type { WorkletMessage } from './workletMessage.js'
import { processorName } from './workletMessage.js'

const amplitude = 0.25
const slideCrossfadeSeconds = 0.02
const newReedCrossfadeSeconds = 0.05
const reedStopsInSeconds = 0.02

export class SineWaveAudioEngine implements AudioEngine {
    private context: AudioContext | null = null
    private node: AudioWorkletNode | null = null

    constructor(
        private readonly workletUrl: string,
        private readonly log: Log
    ) {}

    async prepare(): Promise<void> {
        if (this.node !== null) return this.resume()

        const context = new AudioContext({ latencyHint: 'interactive' })
        await context.audioWorklet.addModule(this.workletUrl)
        const node = new AudioWorkletNode(context, processorName, {
            numberOfInputs: 0,
            numberOfOutputs: 1,
            outputChannelCount: [1],
            processorOptions: { amplitude }
        })
        node.connect(context.destination)
        this.context = context
        this.node = node
        await this.resume()
        this.log.record(`audio started at ${context.sampleRate} Hz`)
    }

    soundTones(tones: readonly Tone[], change: ToneChange): void {
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

    private async resume(): Promise<void> {
        if (this.context?.state === 'suspended') await this.context.resume()
    }

    private send(message: WorkletMessage): void {
        this.node?.port.postMessage(message)
    }
}

function crossfadeSecondsFor(change: ToneChange): number {
    return change === 'newReed' ? newReedCrossfadeSeconds : slideCrossfadeSeconds
}
