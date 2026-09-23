import type { AudioEngineError } from '../../core/audioEngine.js'
import type { SoundingHoleDTO, HarmonicaDTO } from '../../core/harmonicaDTO.js'
import { holesWideOfTheContact } from '../../core/harmonicaDTO.js'
import type { TuneDTO } from '../../core/tuneDTO.js'
import { keyNames, nameOf } from './noteNames.js'
import type {
    DemoViewState,
    FingerMarksViewState,
    FingerWidthViewState,
    HarmonicaViewState,
    HoleViewState,
    KeyViewState,
    LitHalf,
    NoteCountViewState,
    NotesPerFingerViewState,
    PlayingStyleChoice,
    PlayingStyleViewState,
    ToneShapingViewState,
    TuneViewState
} from './harmonicaViewState.js'
import { playingStyleChoices } from './harmonicaViewState.js'

const noRecordingsText = 'Sound is unavailable: the recordings are not on the page.'
const outputRefusedText = 'Sound is unavailable: the audio output would not start.'
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
const notesByPressureLabel = 'by pressure'

const everyHole: readonly number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const noteCountChoices: readonly NoteCountViewState[] =
    [1, 2, 3, 4].map(count => ({ count, name: count === 1 ? '1 note' : `${count} notes` }))
const notesByPressureChoices: readonly NoteCountViewState[] =
    [{ count: holesWideOfTheContact, name: notesByPressureLabel }]

export class HarmonicaPresenter {
    private readonly tunes: readonly TuneViewState[]
    private readonly styleChoices: readonly PlayingStyleChoice[]

    constructor(tunes: readonly TuneDTO[], offersNotesByPressure: boolean) {
        this.tunes = tunes.map((tune, index) => ({ id: index, name: tune.name }))
        this.styleChoices = offersNotesByPressure
            ? playingStyleChoices
            : playingStyleChoices.filter(choice => choice !== 'oneFingerNotesByPressure')
    }

    present(harmonica: HarmonicaDTO, playingAScore: boolean): HarmonicaViewState {
        const style = choiceOf(harmonica)
        return {
            kind: 'ready',
            playable: {
                holes: holeStates(harmonica),
                key: keyState(harmonica.keyPosition),
                style: styleState(style, this.styleChoices),
                notesPerFinger: notesPerFingerState(style, harmonica.mouthHolesWide),
                fingerMarks: fingerMarksState(style, harmonica.mouthHolesWide),
                demo: this.demoState(playingAScore),
                toneShaping: toneShapingState(harmonica)
            }
        }
    }

    presentSoundUnavailable(because: AudioEngineError): HarmonicaViewState {
        return { kind: 'soundUnavailable', text: reasonFor(because) }
    }

    private demoState(isPlaying: boolean): DemoViewState {
        return {
            label: isPlaying ? stopDemoLabel : playDemoLabel,
            tunes: this.tunes,
            isPlaying
        }
    }
}

function reasonFor(failure: AudioEngineError): string {
    switch (failure.kind) {
        case 'noRecordings': return noRecordingsText
        case 'recordingUnreadable': return `Sound is unavailable: the recording ${failure.recording} could not be read.`
        case 'outputRefused': return outputRefusedText
    }
}

function holeStates(harmonica: HarmonicaDTO): HoleViewState[] {
    return everyHole.map(hole => holeState(hole, harmonica.sounding.find(each => each.hole === hole)))
}

function holeState(hole: number, sounding: SoundingHoleDTO | undefined): HoleViewState {
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

function effectOf(reed: SoundingHoleDTO): string {
    if (!reed.isShifted) return ''

    return `(${nameOf(reed.unbent)} ${effectNameOf(reed)})`
}

function effectNameOf(reed: SoundingHoleDTO): string {
    if (!reed.isOverbent) return bendEffectLabel

    return reed.breath === 'blow' ? overblowEffectLabel : overdrawEffectLabel
}

function toneShapingState(harmonica: HarmonicaDTO): ToneShapingViewState {
    return {
        overbendLabel: overbendLabelFor(harmonica.breath),
        bendLabel,
        vibratoLabel,
        isOverbendAvailable: harmonica.canOverbend,
        isBendAvailable: harmonica.canBend
    }
}

function overbendLabelFor(breath: 'blow' | 'draw' | null): string {
    if (breath === null) return overbendAtRestLabel

    return breath === 'blow' ? overblowLabel : overdrawLabel
}

function styleState(chosen: PlayingStyleChoice, offered: readonly PlayingStyleChoice[]): PlayingStyleViewState {
    return {
        chosen,
        label: nameOfChoice(chosen),
        choices: offered.map(each => ({ id: each, name: nameOfChoice(each) }))
    }
}

function choiceOf(harmonica: HarmonicaDTO): PlayingStyleChoice {
    switch (harmonica.style) {
        case 'severalFingersOneNote': return 'severalFingersOneNote'
        case 'oneFingerSeveralNotes': return oneFingerChoiceOf(harmonica.mouthHolesWide)
        default: return 'severalFingersSeveralNotes'
    }
}

function oneFingerChoiceOf(holesWide: number): PlayingStyleChoice {
    return holesWide === holesWideOfTheContact ? 'oneFingerNotesByPressure' : 'oneFingerSeveralNotes'
}

function nameOfChoice(choice: PlayingStyleChoice): string {
    switch (choice) {
        case 'severalFingersSeveralNotes': return 'Many fingers, many notes'
        case 'severalFingersOneNote': return 'Many fingers, one note'
        case 'oneFingerSeveralNotes': return 'One finger, many notes'
        case 'oneFingerNotesByPressure': return 'One finger, notes by pressure'
    }
}

function notesPerFingerState(style: PlayingStyleChoice, holesWide: number): NotesPerFingerViewState {
    switch (style) {
        case 'severalFingersOneNote':
            return { chosen: 1, choices: noteCountChoices, isAvailable: false }
        case 'oneFingerNotesByPressure':
            return { chosen: holesWideOfTheContact, choices: notesByPressureChoices, isAvailable: false }
        default:
            return { chosen: holesWide, choices: noteCountChoices, isAvailable: true }
    }
}

function fingerMarksState(style: PlayingStyleChoice, holesWide: number): FingerMarksViewState {
    return {
        width: fingerWidthState(style, holesWide),
        drawsOnlyTheDecidingFinger: style === 'oneFingerSeveralNotes' || style === 'oneFingerNotesByPressure'
    }
}

function fingerWidthState(style: PlayingStyleChoice, holesWide: number): FingerWidthViewState {
    switch (style) {
        case 'severalFingersOneNote': return { kind: 'resting' }
        case 'oneFingerNotesByPressure': return { kind: 'pressed' }
        default: return { kind: 'holesWide', holes: holesWide }
    }
}

function keyState(position: number): KeyViewState {
    return {
        label: keyNames[position] ?? '',
        position,
        highestPosition: keyNames.length - 1
    }
}
