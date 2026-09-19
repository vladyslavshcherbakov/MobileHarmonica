import type { CoreAudio, CoreFinger, CoreState, CoreToneChange, CoreTune } from './coreState.js'
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

    static async load(url: string, audio: CoreAudio, log: (line: string) => void): Promise<HarmonicaCore> {
        const wasi = wasiHost(log)
        const instrument = new HarmonicaHost(audio, log)
        const { instance } = await WebAssembly.instantiateStreaming(fetch(url), {
            wasi_snapshot_preview1: wasi.imports,
            harmonica: instrument.imports
        })
        const exports = instance.exports as unknown as CoreExports
        wasi.useMemory(exports.memory)
        instrument.useMemory(exports.memory)
        exports._initialize?.()
        return new HarmonicaCore(exports)
    }

    start(): CoreState {
        return this.read(this.exports.harmonica_start())
    }

    playAt(fingers: readonly CoreFinger[]): CoreState {
        const written = new Float64Array(this.exports.memory.buffer, this.inputAddress, fingers.length * doublesPerFinger)
        fingers.forEach((finger, index) => {
            written[index * doublesPerFinger] = finger.fractionFromLeftEdge
            written[index * doublesPerFinger + 1] = finger.fractionAboveCentreLine
            written[index * doublesPerFinger + 2] = finger.fractionCoveredEitherSide
        })
        return this.read(this.exports.harmonica_play_at(fingers.length))
    }

    play(holes: readonly number[], breath: 'blow' | 'draw'): CoreState {
        const written = new Float64Array(this.exports.memory.buffer, this.inputAddress, holes.length)
        written.set(holes)
        return this.read(this.exports.harmonica_play_holes(holes.length, breath === 'blow' ? 0 : 1))
    }

    changeKey(sliderPosition: number): CoreState {
        return this.read(this.exports.harmonica_change_key(sliderPosition))
    }

    changeStyle(index: number): CoreState {
        return this.read(this.exports.harmonica_change_style(index))
    }

    changeMouth(holesWide: number): CoreState {
        return this.read(this.exports.harmonica_change_mouth(holesWide))
    }

    shapeTone(pitch: number, vibrato: number): CoreState {
        return this.read(this.exports.harmonica_shape_tone(pitch, vibrato))
    }

    cupHands(fraction: number): CoreState {
        return this.read(this.exports.harmonica_cup_hands(fraction))
    }

    stopPlaying(ringsDown: boolean): CoreState {
        return this.read(this.exports.harmonica_stop_playing(ringsDown ? 0 : 1))
    }

    tunes(): CoreTune[] {
        return this.decode(this.exports.harmonica_tunes()) as CoreTune[]
    }

    private read(length: number): CoreState {
        return this.decode(length) as CoreState
    }

    private decode(length: number): unknown {
        if (length === 0) throw new Error('the instrument answered with nothing')

        const written = new Uint8Array(this.exports.memory.buffer, this.outputAddress, length)
        return JSON.parse(new TextDecoder().decode(written)) as unknown
    }
}

class HarmonicaHost {
    private memory: WebAssembly.Memory | null = null

    constructor(
        private readonly audio: CoreAudio,
        private readonly log: (line: string) => void
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
            log: (line: number, length: number, isSample: number) => {
                this.log(this.text(line, length))
                void isSample
            }
        }
    }

    private tones(at: number, count: number): { hertz: number; bendableSemitones: number }[] {
        const read = new Float64Array(this.buffer(), at, count * 2)
        return Array.from({ length: count }, (_, index) => ({
            hertz: read[index * 2] as number,
            bendableSemitones: read[index * 2 + 1] as number
        }))
    }

    private text(at: number, length: number): string {
        return new TextDecoder().decode(new Uint8Array(this.buffer(), at, length))
    }

    private buffer(): ArrayBuffer {
        return (this.memory as WebAssembly.Memory).buffer as ArrayBuffer
    }
}
