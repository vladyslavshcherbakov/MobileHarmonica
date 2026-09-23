const namesAboveC = ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B']
const semitonesPerOctave = 12

export const keyNames: readonly string[] =
    ['G', 'A♭', 'A', 'B♭', 'B', 'C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯']

export function nameOf(midiNote: number): string {
    const semitones = ((midiNote % semitonesPerOctave) + semitonesPerOctave) % semitonesPerOctave
    const octave = Math.floor(midiNote / semitonesPerOctave) - 1
    return `${namesAboveC[semitones] ?? ''}${octave}`
}
