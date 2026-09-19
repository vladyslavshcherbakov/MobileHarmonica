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
    readonly spansTheMouth: boolean
    readonly onlyTheDecidingFinger: boolean
    readonly holesWide: number
}

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
    readonly overbendIsAvailable: boolean
    readonly bendIsAvailable: boolean
}
