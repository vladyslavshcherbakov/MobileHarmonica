import type { Breath } from '../../domain/instrument/breath.js'
import type { Harmonica, SoundingReed } from '../../domain/instrument/harmonica.js'
import type { Hole } from '../../domain/instrument/hole.js'
import { holes as everyHole } from '../../domain/instrument/hole.js'
import type { HarmonicaKey } from '../../domain/instrument/harmonicaKey.js'
import { highestSliderPosition, sliderPosition } from '../../domain/instrument/harmonicaKey.js'
import { nameOf } from '../../domain/instrument/midiNote.js'
import type { CupDepth } from '../../domain/playing/cupDepth.js'
import { mouthWidths } from '../../domain/playing/mouthWidth.js'
import type { PlayingStyle } from '../../domain/playing/playingStyle.js'
import { coversTheContactWidth, playingStyles, takesTheTopmostFingerOnly } from '../../domain/playing/playingStyle.js'
import type { Score } from '../../domain/scores/score.js'
import type {
    CupViewState,
    DemoViewState,
    FingerMarksViewState,
    HarmonicaViewState,
    HoleViewState,
    KeyViewState,
    LitHalf,
    MouthViewState,
    PlayingStyleChoice,
    PlayingStyleViewState,
    ToneShapingViewState,
    TuneViewState
} from './harmonicaViewState.js'

const soundUnavailableText = 'Sound is unavailable.'
const overbendAtRestLabel = 'overbend ↑'
const overblowLabel = 'overblow ↑'
const overdrawLabel = 'overdraw ↑'
const bendLabel = 'bend ↓'
const vibratoLabel = 'vibrato →'
const cupLabel = 'cup'
const mouthLabel = 'mouth'
const playDemoLabel = 'play'
const stopDemoLabel = 'stop'
const bendEffectLabel = 'bend'
const overblowEffectLabel = 'overblow'
const overdrawEffectLabel = 'overdraw'

export class HarmonicaPresenter {
    private readonly tunes: readonly TuneViewState[]

    constructor(tunes: readonly Score[]) {
        this.tunes = tunes.map((tune, index) => ({ id: index, name: tune.name }))
    }

    present(harmonica: Harmonica, playingAScore: boolean): HarmonicaViewState {
        return {
            kind: 'ready',
            playable: {
                holes: holeStates(harmonica),
                key: keyState(harmonica.key),
                style: styleState(harmonica.style),
                mouth: mouthState(harmonica.style, harmonica.mouthWidth),
                fingerMarks: fingerMarksState(harmonica.style, harmonica.mouthWidth),
                cup: cupState(harmonica.cup),
                demo: this.demoState(playingAScore),
                toneShaping: toneShapingState(harmonica)
            }
        }
    }

    presentSoundUnavailable(): HarmonicaViewState {
        return { kind: 'soundUnavailable', text: soundUnavailableText }
    }

    private demoState(isPlaying: boolean): DemoViewState {
        return {
            label: isPlaying ? stopDemoLabel : playDemoLabel,
            tunes: this.tunes,
            isPlaying
        }
    }
}

function holeStates(harmonica: Harmonica): HoleViewState[] {
    return everyHole.map(hole => holeState(hole, harmonica.sounding.get(hole)))
}

function holeState(hole: Hole, sounding: SoundingReed | undefined): HoleViewState {
    return {
        id: hole,
        label: String(hole),
        note: sounding === undefined ? '' : nameOf(sounding.pitch),
        effect: sounding === undefined ? '' : effectOf(sounding),
        lit: sounding === undefined ? null : halfLitBy(sounding.breath)
    }
}

function halfLitBy(breath: Breath): LitHalf {
    return breath === 'blow' ? 'top' : 'bottom'
}

function effectOf(reed: SoundingReed): string {
    if (!reed.isShifted) return ''

    return `(${nameOf(reed.unbent)} ${effectNameOf(reed)})`
}

function effectNameOf(reed: SoundingReed): string {
    if (!reed.isOverbent) return bendEffectLabel

    return reed.breath === 'blow' ? overblowEffectLabel : overdrawEffectLabel
}

function toneShapingState(harmonica: Harmonica): ToneShapingViewState {
    return {
        overbendLabel: overbendLabelFor(harmonica.breath),
        bendLabel,
        vibratoLabel,
        overbendIsAvailable: harmonica.canOverbend,
        bendIsAvailable: harmonica.canBend
    }
}

function overbendLabelFor(breath: Breath | null): string {
    if (breath === null) return overbendAtRestLabel

    return breath === 'blow' ? overblowLabel : overdrawLabel
}

function styleState(style: PlayingStyle): PlayingStyleViewState {
    return {
        chosen: choiceOf(style),
        label: nameOfChoice(choiceOf(style)),
        choices: playingStyles.map(each => ({ id: choiceOf(each), name: nameOfChoice(choiceOf(each)) }))
    }
}

function choiceOf(style: PlayingStyle): PlayingStyleChoice {
    switch (style) {
        case 'severalFingersSeveralNotes': return 'severalFingersSeveralNotes'
        case 'severalFingersOneNote': return 'severalFingersOneNote'
        case 'oneFingerSeveralNotes': return 'oneFingerSeveralNotes'
    }
}

function nameOfChoice(choice: PlayingStyleChoice): string {
    switch (choice) {
        case 'severalFingersSeveralNotes': return 'Many fingers, many notes'
        case 'severalFingersOneNote': return 'Many fingers, one note'
        case 'oneFingerSeveralNotes': return 'One finger, many notes'
    }
}

function mouthState(style: PlayingStyle, holesWide: number): MouthViewState {
    return {
        label: mouthLabel,
        holesWide,
        widths: [...mouthWidths],
        isAvailable: coversTheContactWidth(style)
    }
}

function fingerMarksState(style: PlayingStyle, holesWide: number): FingerMarksViewState {
    return {
        spansTheMouth: coversTheContactWidth(style),
        onlyTheDecidingFinger: takesTheTopmostFingerOnly(style),
        holesWide
    }
}

function cupState(cup: CupDepth): CupViewState {
    return { label: cupLabel, closed: cup }
}

function keyState(key: HarmonicaKey): KeyViewState {
    return {
        label: key,
        position: sliderPosition(key),
        highestPosition: highestSliderPosition
    }
}
