export type PlayingStyle =
    | 'severalFingersSeveralNotes'
    | 'severalFingersOneNote'
    | 'oneFingerSeveralNotes'

export const playingStyles: readonly PlayingStyle[] =
    ['severalFingersSeveralNotes', 'severalFingersOneNote', 'oneFingerSeveralNotes']

export function coversTheContactWidth(style: PlayingStyle): boolean {
    return style !== 'severalFingersOneNote'
}

export function takesTheTopmostFingerOnly(style: PlayingStyle): boolean {
    return style === 'oneFingerSeveralNotes'
}
