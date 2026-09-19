import type { SoundingTone, WorkletMessage, WorkletReport } from './workletMessage.js'
import type { RecordedNote, SampleBank } from './sampleBank.js'

const processorName = 'harmonica'

const reedSpeaksInSeconds = 0.005
const openCupHertz = 20000
const closedCupHertz = 800
const reedsOneMouthCovers = 4
const ringDownCycles = 30
const inaudibleGain = 0.001
const vibratoHertz = 5.5
const vibratoPitchAtFullDepth = 0.015
const vibratoDipAtFullDepth = 0.25
const vibratoDriftHertz = 0.23
const vibratoRateDrift = 0.08
const vibratoDepthDrift = 0.2
const radiansPerCycle = 2 * Math.PI
const sineLoopCycles = 44
const sineRootHertz = 440

export const silentBank: SampleBank = { frames: new Float32Array(0), notes: [] }

export function sineBank(atSampleRate: number): SampleBank {
    const frameCount = Math.round((sineLoopCycles * atSampleRate) / sineRootHertz)
    const frames = new Float32Array(frameCount)
    for (let frame = 0; frame < frameCount; frame += 1) {
        frames[frame] = Math.sin((radiansPerCycle * sineRootHertz * frame) / atSampleRate)
    }
    return {
        frames,
        notes: [{
            start: 0,
            loopStart: 0,
            loopEnd: frameCount,
            rootHertz: sineRootHertz,
            sampleRate: atSampleRate
        }]
    }
}

export function nearestRecording(bank: SampleBank, hertz: number): RecordedNote | null {
    let nearest: RecordedNote | null = null
    let closest = Number.POSITIVE_INFINITY
    for (const note of bank.notes) {
        const distance = Math.abs(Math.log2(hertz / note.rootHertz))
        if (distance < closest) {
            closest = distance
            nearest = note
        }
    }
    return nearest
}

export class Oscillator {
    private readonly voices: Voice[] = []
    private breathGain = 0
    private requestedBreathGain = 0
    private requestedBend = 0
    private requestedVibrato = 0
    private requestedCup = 0
    private crossfadeSeconds = 0.02
    private voicesEverSounded = 0
    private lfoPhase = 0
    private driftPhase = 0
    private cupped = 0
    private ringingDown = false

    constructor(
        private samples: SampleBank,
        private readonly sampleRate: number
    ) {}

    useRecordings(samples: SampleBank): void {
        this.samples = samples
        this.voices.length = 0
    }

    sound(tones: readonly SoundingTone[], crossfadeSeconds: number, everyReedSpeaksAgain: boolean): void {
        const playable = this.recorded(tones)
        this.crossfadeSeconds = crossfadeSeconds
        this.ringingDown = false
        for (const voice of this.voices) {
            if (everyReedSpeaksAgain || !isStillWanted(voice, playable)) voice.targetGain = 0
        }
        for (const wanted of playable) {
            if (!this.isRisingAt(wanted.tone.hertz)) this.add(wanted)
        }
    }

    changeBreathGain(gain: number): void {
        this.requestedBreathGain = gain
    }

    changeBend(fraction: number): void {
        this.requestedBend = fraction
    }

    changeVibrato(fraction: number): void {
        this.requestedVibrato = fraction
    }

    cupHands(fraction: number): void {
        this.requestedCup = fraction
    }

    ringDown(): void {
        this.ringingDown = true
        for (const voice of this.voices) voice.targetGain = 0
    }

    damp(seconds: number): void {
        this.ringingDown = false
        this.crossfadeSeconds = seconds
        for (const voice of this.voices) voice.targetGain = 0
    }

    render(into: Float32Array, amplitude: number): void {
        if (this.voices.length === 0) {
            into.fill(0)
            return
        }

        this.bendEveryVoice()
        this.prepareRingDown()
        const vibrato = this.driftedVibrato(into.length)
        const ramp = this.gainRamp()
        const cupCoefficient = this.cupCoefficient()
        for (let frame = 0; frame < into.length; frame += 1) {
            into[frame] = this.nextSample(ramp, vibrato, cupCoefficient) * amplitude
        }
        this.dropSilentVoices()
    }

    private recorded(tones: readonly SoundingTone[]): PlayableTone[] {
        const playable: PlayableTone[] = []
        for (const tone of tones) {
            const recorded = nearestRecording(this.samples, tone.hertz)
            if (recorded !== null) playable.push({ tone, recorded })
        }
        return playable
    }

    private add(wanted: PlayableTone): void {
        this.voicesEverSounded += 1
        this.voices.push(new Voice(wanted.tone, wanted.recorded, this.voicesEverSounded))
    }

    private isRisingAt(hertz: number): boolean {
        return this.voices.some(voice => voice.hertz === hertz && voice.targetGain > 0)
    }

    private bendEveryVoice(): void {
        for (const voice of this.voices) voice.bend(this.requestedBend)
    }

    private prepareRingDown(): void {
        if (!this.ringingDown) return

        for (const voice of this.voices) voice.ringDown(ringDownCycles, this.sampleRate)
    }

    private gainRamp(): GainRamp {
        return {
            rising: 1 / (reedSpeaksInSeconds * this.sampleRate),
            falling: 1 / (this.crossfadeSeconds * this.sampleRate)
        }
    }

    private cupCoefficient(): number {
        const hertz = openCupHertz * Math.pow(closedCupHertz / openCupHertz, this.requestedCup)
        return 1 - Math.exp((-radiansPerCycle * hertz) / this.sampleRate)
    }

    private driftedVibrato(frameCount: number): VibratoSettings {
        this.driftPhase = advanced(this.driftPhase, (vibratoDriftHertz * frameCount) / this.sampleRate)
        const wandering = Math.sin(this.driftPhase)
        return {
            hertz: vibratoHertz * (1 + vibratoRateDrift * wandering),
            depth: this.requestedVibrato * (1 - (vibratoDepthDrift * (1 + wandering)) / 2)
        }
    }

    private nextSample(ramp: GainRamp, vibrato: VibratoSettings, cupCoefficient: number): number {
        this.breathGain = ramped(this.breathGain, this.requestedBreathGain, ramp)
        const scale = this.breathGain / this.airSpreadAcrossTheReeds()
        const swinging = this.nextVibrato(vibrato)

        let mixed = 0
        for (const voice of this.voices) {
            mixed += voice.nextSample(this.samples.frames, this.sampleRate, ramp, swinging.pitchRatio)
        }
        this.cupped += (mixed * scale * swinging.gain - this.cupped) * cupCoefficient
        return this.cupped
    }

    private airSpreadAcrossTheReeds(): number {
        let soundingGain = 0
        for (const voice of this.voices) soundingGain += voice.gain

        return Math.max(1, soundingGain / reedsOneMouthCovers)
    }

    private nextVibrato(vibrato: VibratoSettings): Vibrato {
        this.lfoPhase = advanced(this.lfoPhase, vibrato.hertz / this.sampleRate)
        const swing = Math.sin(this.lfoPhase)
        return {
            pitchRatio: 1 + vibrato.depth * vibratoPitchAtFullDepth * swing,
            gain: 1 - (vibrato.depth * vibratoDipAtFullDepth * (1 + swing)) / 2
        }
    }

    private dropSilentVoices(): void {
        for (let index = this.voices.length - 1; index >= 0; index -= 1) {
            if (this.voices[index]?.isSilent === true) this.voices.splice(index, 1)
        }
    }
}

interface PlayableTone {
    readonly tone: SoundingTone
    readonly recorded: RecordedNote
}

interface GainRamp {
    readonly rising: number
    readonly falling: number
}

interface VibratoSettings {
    readonly hertz: number
    readonly depth: number
}

interface Vibrato {
    readonly pitchRatio: number
    readonly gain: number
}

class Voice {
    readonly hertz: number
    readonly bendableSemitones: number

    position = 0
    gain = 0
    targetGain = 1
    bendRatio = 1
    decayPerSample = 0

    constructor(
        tone: SoundingTone,
        private readonly recorded: RecordedNote,
        readonly number: number
    ) {
        this.hertz = tone.hertz
        this.bendableSemitones = tone.bendableSemitones
    }

    get isSilent(): boolean {
        return this.gain <= inaudibleGain && this.targetGain <= 0
    }

    ringDown(cycles: number, sampleRate: number): void {
        this.decayPerSample = Math.pow(inaudibleGain, this.hertz / (cycles * sampleRate))
    }

    bend(fraction: number): void {
        this.bendRatio = Math.pow(2, (-this.bendableSemitones * fraction) / 12)
    }

    nextSample(frames: Float32Array, sampleRate: number, ramp: GainRamp, pitchRatio: number): number {
        const value = this.interpolated(frames) * this.gain
        this.position += this.positionIncrement(sampleRate, pitchRatio)
        this.wrapIntoTheLoop()
        this.advanceGain(ramp)
        return value
    }

    private advanceGain(ramp: GainRamp): void {
        if (this.decayPerSample > 0 && this.targetGain <= 0) {
            this.gain *= this.decayPerSample
            return
        }

        this.gain = ramped(this.gain, this.targetGain, ramp)
    }

    private interpolated(frames: Float32Array): number {
        const frame = Math.floor(this.position)
        const here = frames[this.recorded.start + frame] ?? 0
        const nextFrame = frame + 1 < this.recorded.loopEnd ? frame + 1 : this.recorded.loopStart
        const next = frames[this.recorded.start + nextFrame] ?? 0
        return here + (next - here) * (this.position - frame)
    }

    private positionIncrement(sampleRate: number, pitchRatio: number): number {
        return ((this.hertz * this.bendRatio * pitchRatio) / this.recorded.rootHertz)
            * (this.recorded.sampleRate / sampleRate)
    }

    private wrapIntoTheLoop(): void {
        const length = this.recorded.loopEnd - this.recorded.loopStart
        while (this.position >= this.recorded.loopEnd) {
            this.position -= length
        }
    }
}

function isStillWanted(voice: Voice, playable: readonly PlayableTone[]): boolean {
    return voice.targetGain > 0 && playable.some(wanted => wanted.tone.hertz === voice.hertz)
}

function advanced(phase: number, cycles: number): number {
    return (phase + radiansPerCycle * cycles) % radiansPerCycle
}

function ramped(gain: number, target: number, ramp: GainRamp): number {
    return gain < target ? Math.min(target, gain + ramp.rising) : Math.max(target, gain - ramp.falling)
}

export function registerHarmonicaProcessor(): void {
    class HarmonicaProcessor extends AudioWorkletProcessor {
        private readonly oscillator: Oscillator
        private readonly amplitude: number
        private waitingToSpeak = false

        constructor(options?: { processorOptions?: unknown }) {
            super(options)
            const settings = (options?.processorOptions ?? {}) as { amplitude?: number }
            this.amplitude = settings.amplitude ?? 0.25
            this.oscillator = new Oscillator(silentBank, sampleRate)
            this.port.onmessage = event => this.receive(event.data as WorkletMessage)
        }

        process(_inputs: Float32Array[][], outputs: Float32Array[][]): boolean {
            const output = outputs[0]
            const channel = output?.[0]
            if (channel === undefined) return true

            this.oscillator.render(channel, this.amplitude)
            this.reportSpeaking(channel)
            for (let index = 1; index < (output?.length ?? 0); index += 1) {
                output?.[index]?.set(channel)
            }
            return true
        }

        private reportSpeaking(channel: Float32Array): void {
            if (!this.waitingToSpeak) return

            for (const sample of channel) {
                if (sample === 0) continue

                this.waitingToSpeak = false
                this.report({ kind: 'speaking', at: currentTime })
                return
            }
        }

        private report(report: WorkletReport): void {
            this.port.postMessage(report)
        }

        private receive(message: WorkletMessage): void {
            switch (message.kind) {
                case 'samples':
                    this.oscillator.useRecordings({ frames: message.frames, notes: message.notes })
                    return
                case 'sound':
                    this.oscillator.sound(message.tones, message.crossfadeSeconds, message.everyReedSpeaksAgain)
                    this.waitingToSpeak = message.tones.length > 0
                    this.report({ kind: 'took', at: currentTime })
                    return
                case 'breathGain':
                    this.oscillator.changeBreathGain(message.value)
                    return
                case 'bend':
                    this.oscillator.changeBend(message.value)
                    return
                case 'vibrato':
                    this.oscillator.changeVibrato(message.value)
                    return
                case 'cup':
                    this.oscillator.cupHands(message.value)
                    return
                case 'ringDown':
                    this.oscillator.ringDown()
                    return
                case 'damp':
                    this.oscillator.damp(message.seconds)
                    return
            }
        }
    }

    registerProcessor(processorName, HarmonicaProcessor)
}

if (typeof registerProcessor === 'function') registerHarmonicaProcessor()
