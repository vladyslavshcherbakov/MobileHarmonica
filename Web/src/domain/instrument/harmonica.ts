import type { Breath } from './breath.js'
import type { Hole } from './hole.js'
import type { HarmonicaKey } from './harmonicaKey.js'
import type { MidiNote } from './midiNote.js'
import { hertzOf, transposedBy } from './midiNote.js'
import type { Tone } from './tone.js'
import type { BendDepth } from '../playing/bendDepth.js'
import type { CupDepth } from '../playing/cupDepth.js'
import type { OverbendDepth } from '../playing/overbendDepth.js'
import type { PlayingStyle } from '../playing/playingStyle.js'
import type { MouthWidth } from '../playing/mouthWidth.js'

export class SoundingReed {
    constructor(
        readonly breath: Breath,
        readonly unbent: MidiNote,
        readonly bendableSemitones: number,
        readonly overbendableSemitones: number,
        readonly bend: BendDepth,
        readonly overbend: OverbendDepth
    ) {}

    get tone(): Tone {
        return this.isOverbent
            ? { hertz: hertzOf(this.pitch), bendableSemitones: 0 }
            : { hertz: hertzOf(this.unbent), bendableSemitones: this.bendableSemitones }
    }

    get pitch(): MidiNote {
        return transposedBy(this.unbent, Math.round(this.shiftedSemitones))
    }

    get isShifted(): boolean {
        return this.pitch !== this.unbent
    }

    get isOverbent(): boolean {
        return this.pitch > this.unbent
    }

    get canBend(): boolean {
        return this.bendableSemitones > 0
    }

    get canOverbend(): boolean {
        return this.overbendableSemitones > 0
    }

    private get shiftedSemitones(): number {
        return this.overbendableSemitones * this.overbend - this.bendableSemitones * this.bend
    }
}

export class Harmonica {
    constructor(
        readonly key: HarmonicaKey,
        readonly style: PlayingStyle,
        readonly mouthWidth: MouthWidth,
        readonly cup: CupDepth,
        readonly sounding: ReadonlyMap<Hole, SoundingReed>
    ) {}

    get soundingHoles(): Hole[] {
        return [...this.sounding.keys()]
    }

    get breath(): Breath | null {
        for (const reed of this.sounding.values()) return reed.breath

        return null
    }

    get canBend(): boolean {
        return [...this.sounding.values()].some(reed => reed.canBend)
    }

    get canOverbend(): boolean {
        return [...this.sounding.values()].some(reed => reed.canOverbend)
    }
}
