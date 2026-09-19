export type MidiNote = number

export const namesAboveC =
    ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B']

const concertPitchHertz = 440
const concertPitchNumber = 69
const semitonesPerOctave = 12

export function transposedBy(note: MidiNote, semitones: number): MidiNote {
    return note + semitones
}

export function hertzOf(note: MidiNote): number {
    return concertPitchHertz * Math.pow(2, (note - concertPitchNumber) / semitonesPerOctave)
}

export function semitonesAboveC(note: MidiNote): number {
    return ((note % semitonesPerOctave) + semitonesPerOctave) % semitonesPerOctave
}

export function octaveOf(note: MidiNote): number {
    return Math.floor(note / semitonesPerOctave) - 1
}

export function nameOf(note: MidiNote): string {
    return (namesAboveC[semitonesAboveC(note)] ?? '') + String(octaveOf(note))
}
