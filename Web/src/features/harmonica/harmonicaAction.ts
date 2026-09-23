import type { AreaSize } from './touch/areaSize.js'
import type { Contact } from './touch/contact.js'

export type HarmonicaAction =
    | { readonly kind: 'startButtonTapped' }
    | { readonly kind: 'pageHidden' }
    | { readonly kind: 'stripTouched'; readonly contacts: readonly Contact[]; readonly across: AreaSize }
    | { readonly kind: 'keySliderMoved'; readonly position: number }
    | { readonly kind: 'styleChosen'; readonly named: string }
    | { readonly kind: 'notesPerFingerChosen'; readonly notes: number }
    | { readonly kind: 'tuneChosen'; readonly index: number }
    | { readonly kind: 'stopTuneButtonTapped' }
    | { readonly kind: 'shapingPadTouched'; readonly contacts: readonly Contact[]; readonly across: AreaSize }
    | { readonly kind: 'shapingPadPinched'; readonly magnification: number }
