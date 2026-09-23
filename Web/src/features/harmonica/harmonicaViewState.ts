export type HarmonicaViewState =
    | { readonly kind: 'preparingSound' }
    | { readonly kind: 'ready'; readonly playable: PlayableHarmonica }
    | { readonly kind: 'soundUnavailable'; readonly text: string }

export interface PlayableHarmonica {
    readonly holes: readonly HoleViewState[]
    readonly key: KeyViewState
    readonly style: PlayingStyleViewState
    readonly notesPerFinger: NotesPerFingerViewState
    readonly fingerMarks: FingerMarksViewState
    readonly demo: DemoViewState
    readonly toneShaping: ToneShapingViewState
}

export type LitHalf = 'top' | 'bottom'

export interface HoleViewState {
    readonly id: number
    readonly label: string
    readonly note: string
    readonly effect: string
    readonly lit: LitHalf | null
}

export interface KeyViewState {
    readonly label: string
    readonly position: number
    readonly highestPosition: number
}

export type PlayingStyleChoice =
    | 'severalFingersSeveralNotes'
    | 'severalFingersOneNote'
    | 'oneFingerSeveralNotes'
    | 'oneFingerNotesByPressure'

export const playingStyleChoices: readonly PlayingStyleChoice[] =
    ['severalFingersSeveralNotes', 'severalFingersOneNote', 'oneFingerSeveralNotes', 'oneFingerNotesByPressure']

export function isPlayingStyleChoice(value: string): value is PlayingStyleChoice {
    return playingStyleChoices.some(choice => choice === value)
}

export interface PlayingStyleChoiceViewState {
    readonly id: PlayingStyleChoice
    readonly name: string
}

export interface PlayingStyleViewState {
    readonly chosen: PlayingStyleChoice
    readonly label: string
    readonly choices: readonly PlayingStyleChoiceViewState[]
}

export interface NotesPerFingerViewState {
    readonly chosen: number
    readonly choices: readonly NoteCountViewState[]
    readonly isAvailable: boolean
}

export interface NoteCountViewState {
    readonly count: number
    readonly name: string
}

export interface FingerMarksViewState {
    readonly width: FingerWidthViewState
    readonly drawsOnlyTheDecidingFinger: boolean
}

export type FingerWidthViewState =
    | { readonly kind: 'resting' }
    | { readonly kind: 'holesWide'; readonly holes: number }
    | { readonly kind: 'pressed' }

export interface TuneViewState {
    readonly id: number
    readonly name: string
}

export interface DemoViewState {
    readonly label: string
    readonly tunes: readonly TuneViewState[]
    readonly isPlaying: boolean
}

export interface ToneShapingViewState {
    readonly overbendLabel: string
    readonly bendLabel: string
    readonly vibratoLabel: string
    readonly isOverbendAvailable: boolean
    readonly isBendAvailable: boolean
}
