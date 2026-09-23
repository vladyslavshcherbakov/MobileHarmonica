import type { CoreAudio, CoreToneChange } from './coreAudio.js'
import type { CoreFinger } from './coreFinger.js'
import type { HarmonicaDTO } from './harmonicaDTO.js'
import type { ReedDTO } from './reedDTO.js'
import type { TimingDTO } from './timingDTO.js'
import type { TuneDTO } from './tuneDTO.js'
import type { Log } from '../logging/log.js'
import { wasiHost } from './wasi.js'

const doublesPerFinger = 3
const changes: readonly CoreToneChange[] = ['slide', 'newReed', 'breathReversed']

interface CoreExports {
    readonly memory: WebAssembly.Memory
    readonly _initialize?: () => void
    readonly harmonica_input_buffer: () => number
    readonly harmonica_output_buffer: () => number
    readonly harmonica_start: () => number
    readonly harmonica_play_at: (fingers: number) => number
    readonly harmonica_play_holes: (count: number, breath: number) => number
    readonly harmonica_change_key: (sliderPosition: number) => number
    readonly harmonica_change_style: (index: number) => number
    readonly harmonica_change_mouth: (holesWide: number) => number
    readonly harmonica_shape_tone: (pitch: number, vibrato: number) => number
    readonly harmonica_cup_hands: (fraction: number) => number
    readonly harmonica_stop_playing: (release: number) => number
    readonly harmonica_tunes: () => number
    readonly harmonica_timing: () => number
    readonly harmonica_reeds: () => number
}

export class HarmonicaCore {
    private readonly exports: CoreExports
    private readonly inputAddress: number
    private readonly outputAddress: number

    private constructor(exports: CoreExports) {
        this.exports = exports
        this.inputAddress = exports.harmonica_input_buffer()
        this.outputAddress = exports.harmonica_output_buffer()
    }

    static async load(url: string, audio: CoreAudio, log: Log): Promise<HarmonicaCore> {
        const started = performance.now()
        log.record(`reading the instrument from ${url}`)
        const compiled = await WebAssembly.compileStreaming(fetch(url))
        log.record(`instrument compiled, took ${Math.round(performance.now() - started)} ms`)
        return HarmonicaCore.started(compiled, audio, log)
    }

    static async started(compiled: WebAssembly.Module, audio: CoreAudio, log: Log): Promise<HarmonicaCore> {
        const wasi = wasiHost(line => log.record(line))
        const instrument = new HarmonicaHost(audio, log)
        const instance = await WebAssembly.instantiate(compiled, {
            wasi_snapshot_preview1: wasi.imports,
            harmonica: instrument.imports
        })
        const exports = instance.exports as unknown as CoreExports
        wasi.useMemory(exports.memory)
        instrument.useMemory(exports.memory)
        exports._initialize?.()
        log.record('instrument ready')
        return new HarmonicaCore(exports)
    }

    start(): HarmonicaDTO {
        return this.read(this.exports.harmonica_start())
    }

    playAt(fingers: readonly CoreFinger[]): HarmonicaDTO {
        const fingerDoubles = new Float64Array(this.exports.memory.buffer, this.inputAddress, fingers.length * doublesPerFinger)
        fingers.forEach((finger, index) => {
            fingerDoubles[index * doublesPerFinger] = finger.fractionFromLeftEdge
            fingerDoubles[index * doublesPerFinger + 1] = finger.fractionAboveCentreLine
            fingerDoubles[index * doublesPerFinger + 2] = finger.fractionCoveredEitherSide
        })
        return this.read(this.exports.harmonica_play_at(fingers.length))
    }

    play(holes: readonly number[], breath: 'blow' | 'draw'): HarmonicaDTO {
        const holeDoubles = new Float64Array(this.exports.memory.buffer, this.inputAddress, holes.length)
        holeDoubles.set(holes)
        return this.read(this.exports.harmonica_play_holes(holes.length, breath === 'blow' ? 0 : 1))
    }

    changeKey(sliderPosition: number): HarmonicaDTO {
        return this.read(this.exports.harmonica_change_key(sliderPosition))
    }

    changeStyle(index: number): HarmonicaDTO {
        return this.read(this.exports.harmonica_change_style(index))
    }

    changeMouth(holesWide: number): HarmonicaDTO {
        return this.read(this.exports.harmonica_change_mouth(holesWide))
    }

    shapeTone(pitch: number, vibrato: number): HarmonicaDTO {
        return this.read(this.exports.harmonica_shape_tone(pitch, vibrato))
    }

    cupHands(fraction: number): HarmonicaDTO {
        return this.read(this.exports.harmonica_cup_hands(fraction))
    }

    stopPlaying(ringsDown: boolean): HarmonicaDTO {
        return this.read(this.exports.harmonica_stop_playing(ringsDown ? 0 : 1))
    }

    tunes(): TuneDTO[] {
        return this.decode(this.exports.harmonica_tunes()) as TuneDTO[]
    }

    timing(): TimingDTO {
        return this.decode(this.exports.harmonica_timing()) as TimingDTO
    }

    reeds(): ReedDTO[] {
        return this.decode(this.exports.harmonica_reeds()) as ReedDTO[]
    }

    private read(length: number): HarmonicaDTO {
        return this.decode(length) as HarmonicaDTO
    }

    private decode(length: number): unknown {
        if (length === 0) throw new Error('the instrument answered with nothing')

        const json = new Uint8Array(this.exports.memory.buffer, this.outputAddress, length)
        return JSON.parse(new TextDecoder().decode(json)) as unknown
    }
}

class HarmonicaHost {
    private memory: WebAssembly.Memory | null = null

    constructor(
        private readonly audio: CoreAudio,
        private readonly log: Log
    ) {}

    useMemory(memory: WebAssembly.Memory): void {
        this.memory = memory
    }

    get imports(): Record<string, WebAssembly.ImportValue> {
        return {
            soundTones: (tones: number, count: number, change: number) => {
                this.audio.soundTones(this.tones(tones, count), changes[change] ?? 'slide')
            },
            changeIntensity: (gain: number) => this.audio.changeIntensity(gain),
            changeBend: (fraction: number) => this.audio.changeBend(fraction),
            changeVibrato: (fraction: number) => this.audio.changeVibrato(fraction),
            cupHands: (fraction: number) => this.audio.cupHands(fraction),
            silence: (release: number) => this.audio.silence(release === 0),
            log: (line: number, length: number, isSample: number) => this.write(this.text(line, length), isSample === 1)
        }
    }

    private write(line: string, asSample: boolean): void {
        if (asSample) {
            this.log.recordSample(line)
        } else {
            this.log.record(line)
        }
    }

    private tones(at: number, count: number): { hertz: number; bendableSemitones: number }[] {
        const toneDoubles = new Float64Array(this.buffer(), at, count * 2)
        return Array.from({ length: count }, (_, index) => ({
            hertz: toneDoubles[index * 2] as number,
            bendableSemitones: toneDoubles[index * 2 + 1] as number
        }))
    }

    private text(at: number, length: number): string {
        return new TextDecoder().decode(new Uint8Array(this.buffer(), at, length))
    }

    private buffer(): ArrayBuffer {
        return (this.memory as WebAssembly.Memory).buffer as ArrayBuffer
    }
}
