export type HarmonicaKey =
    | 'G' | 'A♭' | 'A' | 'B♭' | 'B' | 'C'
    | 'D♭' | 'D' | 'E♭' | 'E' | 'F' | 'F♯'

export const keys: readonly HarmonicaKey[] =
    ['G', 'A♭', 'A', 'B♭', 'B', 'C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯']

export const lowestKey: HarmonicaKey = 'G'
export const highestSliderPosition = keys.length - 1

const semitonesFromCOfTheLowest = -5

export function semitonesFromC(key: HarmonicaKey): number {
    return keys.indexOf(key) + semitonesFromCOfTheLowest
}

export function sliderPosition(key: HarmonicaKey): number {
    return keys.indexOf(key)
}

export function keyAtNearestSliderPosition(position: number): HarmonicaKey {
    const within = Math.min(highestSliderPosition, Math.max(0, position))
    return keys[within] ?? 'C'
}

export function keyTransposedBy(semitones: number): HarmonicaKey {
    const semitonesAboveTheLowest = semitones - semitonesFromCOfTheLowest
    return keys[((semitonesAboveTheLowest % 12) + 12) % 12] ?? 'C'
}
