import type { CoreSoundingHole, CoreState, CoreTune } from '../../core/coreState.js'
import { keyNames, nameOf } from './noteNames.js'
import type {
    DemoViewState,
    FingerMarksViewState,
    HarmonicaViewState,
    HoleViewState,
    KeyViewState,
    LitHalf,
    NotesPerFingerViewState,
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
const playDemoLabel = '▶\uFE0E'
const stopDemoLabel = 'stop'
const bendEffectLabel = 'bend'
const overblowEffectLabel = 'overblow'
const overdrawEffectLabel = 'overdraw'

const everyHole: readonly number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const noteCounts: readonly number[] = [1, 2, 3, 4]
const playingStyles: readonly PlayingStyleChoice[] =
    ['severalFingersSeveralNotes', 'severalFingersOneNote', 'oneFingerSeveralNotes']

export class HarmonicaPresenter {
    private readonly tunes: readonly TuneViewState[]

    constructor(tunes: readonly CoreTune[]) {
        this.tunes = tunes.map((tune, index) => ({ id: index, name: tune.name }))
    }

    present(harmonica: CoreState, playingAScore: boolean): HarmonicaViewState {
        return {
            kind: 'ready',
            playable: {
                holes: holeStates(harmonica),
                key: keyState(harmonica.keyPosition),
                style: styleState(harmonica.style),
                notesPerFinger: notesPerFingerState(harmonica.style, harmonica.mouthHolesWide),
                fingerMarks: fingerMarksState(harmonica.style, harmonica.mouthHolesWide),
                demo: this.demoState(playingAScore),
                toneShaping: toneShapingState(harmonica)
            }
        }
    }

    presentSoundUnavailable(reason: string): HarmonicaViewState {
        return { kind: 'soundUnavailable', text: `${soundUnavailableText} ${reason}` }
    }

    private demoState(isPlaying: boolean): DemoViewState {
        return {
            label: isPlaying ? stopDemoLabel : playDemoLabel,
            tunes: this.tunes,
            isPlaying
        }
    }
}

function holeStates(harmonica: CoreState): HoleViewState[] {
    return everyHole.map(hole => holeState(hole, harmonica.sounding.find(each => each.hole === hole)))
}

function holeState(hole: number, sounding: CoreSoundingHole | undefined): HoleViewState {
    return {
        id: hole,
        label: String(hole),
        note: sounding === undefined ? '' : nameOf(sounding.pitch),
        effect: sounding === undefined ? '' : effectOf(sounding),
        lit: sounding === undefined ? null : halfLitBy(sounding.breath)
    }
}

function halfLitBy(breath: 'blow' | 'draw'): LitHalf {
    return breath === 'blow' ? 'top' : 'bottom'
}

function effectOf(reed: CoreSoundingHole): string {
    if (!reed.isShifted) return ''

    return `(${nameOf(reed.unbent)} ${effectNameOf(reed)})`
}

function effectNameOf(reed: CoreSoundingHole): string {
    if (!reed.isOverbent) return bendEffectLabel

    return reed.breath === 'blow' ? overblowEffectLabel : overdrawEffectLabel
}

function toneShapingState(harmonica: CoreState): ToneShapingViewState {
    return {
        overbendLabel: overbendLabelFor(harmonica.breath),
        bendLabel,
        vibratoLabel,
        overbendIsAvailable: harmonica.canOverbend,
        bendIsAvailable: harmonica.canBend
    }
}

function overbendLabelFor(breath: 'blow' | 'draw' | null): string {
    if (breath === null) return overbendAtRestLabel

    return breath === 'blow' ? overblowLabel : overdrawLabel
}

function styleState(style: string): PlayingStyleViewState {
    return {
        chosen: choiceOf(style),
        label: nameOfChoice(choiceOf(style)),
        choices: playingStyles.map(each => ({ id: each, name: nameOfChoice(each) }))
    }
}

function choiceOf(style: string): PlayingStyleChoice {
    switch (style) {
        case 'severalFingersOneNote': return 'severalFingersOneNote'
        case 'oneFingerSeveralNotes': return 'oneFingerSeveralNotes'
        default: return 'severalFingersSeveralNotes'
    }
}

function nameOfChoice(choice: PlayingStyleChoice): string {
    switch (choice) {
        case 'severalFingersSeveralNotes': return 'Many fingers, many notes'
        case 'severalFingersOneNote': return 'Many fingers, one note'
        case 'oneFingerSeveralNotes': return 'One finger, many notes'
    }
}

function notesPerFingerState(style: string, holesWide: number): NotesPerFingerViewState {
    const takesSeveral = style !== 'severalFingersOneNote'
    return {
        chosen: takesSeveral ? holesWide : 1,
        choices: noteCounts.map(count => ({ count, name: count === 1 ? '1 note' : `${count} notes` })),
        isAvailable: takesSeveral
    }
}

function fingerMarksState(style: string, holesWide: number): FingerMarksViewState {
    return {
        spansTheMouth: style !== 'severalFingersOneNote',
        onlyTheDecidingFinger: style === 'oneFingerSeveralNotes',
        holesWide
    }
}

function keyState(position: number): KeyViewState {
    return {
        label: keyNames[position] ?? '',
        position,
        highestPosition: keyNames.length - 1
    }
}
