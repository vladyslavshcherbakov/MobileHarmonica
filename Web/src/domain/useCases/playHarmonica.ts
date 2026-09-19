import type { Breath } from '../instrument/breath.js'
import { breathOfTheTopmost, isCrossingTheBreathBoundary } from '../instrument/breath.js'
import type { Hole } from '../instrument/hole.js'
import { holeAt, holesCovered } from '../instrument/hole.js'
import { Harmonica, SoundingReed } from '../instrument/harmonica.js'
import type { HarmonicaKey } from '../instrument/harmonicaKey.js'
import { semitonesFromC } from '../instrument/harmonicaKey.js'
import type { Reed } from '../instrument/reed.js'
import { isSameReed } from '../instrument/reed.js'
import { bendableSemitones, noteFor, overbendableSemitones } from '../instrument/richterTuning.js'
import type { BendDepth } from '../playing/bendDepth.js'
import type { OverbendDepth } from '../playing/overbendDepth.js'
import type { BreathIntensity } from '../playing/breathIntensity.js'
import { fullPressure, intensityAt } from '../playing/breathIntensity.js'
import type { CupDepth } from '../playing/cupDepth.js'
import { handsOpen } from '../playing/cupDepth.js'
import type { MouthWidth } from '../playing/mouthWidth.js'
import type { PitchShaping } from '../playing/pitchShaping.js'
import { bendOf, overbendOf, restingShaping } from '../playing/pitchShaping.js'
import type { PlayingStyle } from '../playing/playingStyle.js'
import { coversTheContactWidth, takesTheTopmostFingerOnly } from '../playing/playingStyle.js'
import type { PositionOnHarmonica } from '../playing/positionOnHarmonica.js'
import { isOnTheHarmonica, topmostOf } from '../playing/positionOnHarmonica.js'
import type { ReedRelease } from '../playing/reedRelease.js'
import type { ToneChange } from '../playing/toneChange.js'
import type { VibratoDepth } from '../playing/vibratoDepth.js'
import { vibratoOff } from '../playing/vibratoDepth.js'
import type { AudioEngine } from '../protocols/audioEngine.js'
import type { Log } from '../protocols/log.js'

export class PlayHarmonica {
    private soundingReeds: Reed[] = []
    private soundingIntensity: BreathIntensity | null = null
    private shaping: PitchShaping = restingShaping
    private vibrato: VibratoDepth = vibratoOff
    private cup: CupDepth = handsOpen
    private key: HarmonicaKey = 'C'
    private style: PlayingStyle = 'severalFingersSeveralNotes'
    private width: MouthWidth = 2

    constructor(
        private readonly audioEngine: AudioEngine,
        private readonly log: Log
    ) {}

    async prepare(): Promise<Harmonica> {
        await this.audioEngine.prepare()
        this.log.record(`harmonica ready in key ${this.key}`)
        return this.harmonica
    }

    playAt(positions: readonly PositionOnHarmonica[]): Harmonica {
        const sounding = positions.filter(isOnTheHarmonica)
        if (this.isCrossingTheBreathBoundary(sounding)) return this.harmonica

        const reeds = this.reedsUnder(sounding)
        const topmost = topmostOf(sounding)
        if (reeds.length === 0 || topmost === null) return this.stopPlaying('ringsDown')

        this.applyBreathIntensity(intensityAt(topmost))
        if (isTheSameSet(reeds, this.soundingReeds)) return this.harmonica

        this.sound(reeds, this.breathTurnsInto(reeds) ? 'breathReversed' : 'slide')
        return this.harmonica
    }

    play(holes: readonly Hole[], breath: Breath): Harmonica {
        const reeds = holes.map(hole => ({ hole, breath }))
        this.applyBreathIntensity(fullPressure)
        if (isTheSameSet(reeds, this.soundingReeds)) return this.harmonica

        this.sound(reeds, this.breathTurnsInto(reeds) ? 'breathReversed' : 'slide')
        return this.harmonica
    }

    changeStyle(style: PlayingStyle): Harmonica {
        if (style === this.style) return this.harmonica

        this.style = style
        this.log.record(`playing style changed to ${style}`)
        return this.stopPlaying('ringsDown')
    }

    changeMouthWidth(width: MouthWidth): Harmonica {
        if (width === this.width) return this.harmonica

        this.width = width
        this.log.record(`mouth ${width} holes wide`)
        return this.stopPlaying('ringsDown')
    }

    changeKey(key: HarmonicaKey): Harmonica {
        this.key = key
        this.log.record(`key changed to ${key}, ${semitonesFromC(key)} semitones from C`)
        if (this.soundingReeds.length === 0) return this.harmonica

        this.sound(this.soundingReeds, 'slide')
        return this.harmonica
    }

    shapeTone(shaping: PitchShaping, vibrato: VibratoDepth): Harmonica {
        if (shaping === this.shaping && vibrato === this.vibrato) return this.harmonica

        const wasOverbent = this.overbend
        this.shaping = shaping
        this.vibrato = vibrato
        this.log.recordSample(
            `bend ${rounded(this.bend)} of ${rounded(this.semitonesTheMouthCanPull)} semitones,`
            + ` overbend ${rounded(this.overbend)} of ${rounded(this.overbendableSemitones)} semitones,`
            + ` vibrato ${rounded(vibrato)}`
        )
        this.audioEngine.changeBend(this.bend)
        this.audioEngine.changeVibrato(vibrato)
        if (this.overbend === wasOverbent || this.soundingReeds.length === 0) return this.harmonica

        this.sound(this.soundingReeds, 'newReed')
        return this.harmonica
    }

    cupHands(cup: CupDepth): Harmonica {
        if (cup === this.cup) return this.harmonica

        this.cup = cup
        this.audioEngine.cupHands(cup)
        this.log.recordSample(`hands cupped ${rounded(cup)}`)
        return this.harmonica
    }

    stopPlaying(release: ReedRelease): Harmonica {
        if (this.soundingReeds.length === 0) return this.harmonica

        this.audioEngine.silence(release)
        this.log.record(`silent, ${this.describe(this.soundingReeds)} ${release}`)
        this.soundingReeds = []
        this.soundingIntensity = null
        return this.harmonica
    }

    private get harmonica(): Harmonica {
        return new Harmonica(
            this.key,
            this.style,
            this.width,
            this.cup,
            new Map(this.soundingReeds.map(reed => [reed.hole, this.soundingReed(reed)]))
        )
    }

    private get bend(): BendDepth {
        return bendOf(this.shaping)
    }

    private get overbend(): OverbendDepth {
        return overbendOf(this.shaping)
    }

    private get semitonesTheMouthCanPull(): number {
        if (this.soundingReeds.length === 0) return 0

        return Math.min(...this.soundingReeds.map(bendableSemitones))
    }

    private get overbendableSemitones(): number {
        if (this.soundingReeds.length === 0) return 0

        return Math.max(...this.soundingReeds.map(overbendableSemitones))
    }

    private soundingReed(reed: Reed): SoundingReed {
        return new SoundingReed(
            reed.breath,
            noteFor(reed, this.key),
            this.semitonesTheMouthCanPull,
            overbendableSemitones(reed),
            this.bend,
            this.overbend
        )
    }

    private applyBreathIntensity(intensity: BreathIntensity): void {
        if (intensity === this.soundingIntensity) return

        this.audioEngine.changeIntensity(intensity)
        this.soundingIntensity = intensity
        this.log.recordSample(`breath intensity ${rounded(intensity)}`)
    }

    private reedsUnder(positions: readonly PositionOnHarmonica[]): Reed[] {
        const breath = breathOfTheTopmost(positions)
        if (breath === null) return []

        return this.holesUnder(positions).map(hole => ({ hole, breath }))
    }

    private holesUnder(positions: readonly PositionOnHarmonica[]): Hole[] {
        const covered = new Set(this.fingersThatSound(positions).flatMap(position => this.holesFor(position)))
        return [...covered].sort((one, other) => one - other)
    }

    private fingersThatSound(positions: readonly PositionOnHarmonica[]): PositionOnHarmonica[] {
        if (!takesTheTopmostFingerOnly(this.style)) return [...positions]

        const topmost = topmostOf(positions)
        return topmost === null ? [] : [topmost]
    }

    private holesFor(position: PositionOnHarmonica): Hole[] {
        if (!coversTheContactWidth(this.style)) {
            const single = holeAt(position)
            return single === null ? [] : [single]
        }

        return holesCovered(position, this.width)
    }

    private isCrossingTheBreathBoundary(positions: readonly PositionOnHarmonica[]): boolean {
        const topmost = topmostOf(positions)
        if (this.soundingReeds.length === 0 || topmost === null) return false

        return isCrossingTheBreathBoundary(topmost)
    }

    private breathTurnsInto(reeds: readonly Reed[]): boolean {
        const sounding = this.soundingReeds[0]?.breath
        const arriving = reeds[0]?.breath
        if (sounding === undefined || arriving === undefined) return false

        return sounding !== arriving
    }

    private sound(reeds: readonly Reed[], change: ToneChange): void {
        this.soundingReeds = [...reeds]
        this.audioEngine.soundTones(reeds.map(reed => this.soundingReed(reed).tone), change)
        this.log.record(`sounding ${this.describe(reeds)} in key ${this.key}`)
    }

    private describe(reeds: readonly Reed[]): string {
        return reeds
            .map(reed => `hole ${reed.hole} ${reed.breath} ${rounded(this.soundingReed(reed).tone.hertz)} Hz`)
            .join(', ')
    }
}

function isTheSameSet(reeds: readonly Reed[], others: readonly Reed[]): boolean {
    return reeds.length === others.length
        && reeds.every((reed, index) => isSameReed(reed, others[index] as Reed))
}

function rounded(value: number): string {
    return value.toFixed(2)
}
