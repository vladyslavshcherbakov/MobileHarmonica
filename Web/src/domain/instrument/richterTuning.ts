import { reversed } from './breath.js'
import type { Hole } from './hole.js'
import type { HarmonicaKey } from './harmonicaKey.js'
import { semitonesFromC } from './harmonicaKey.js'
import type { MidiNote } from './midiNote.js'
import { transposedBy } from './midiNote.js'
import type { Reed } from './reed.js'

const blowNotes: Record<Hole, MidiNote> = {
    1: 60, 2: 64, 3: 67, 4: 72, 5: 76, 6: 79, 7: 84, 8: 88, 9: 91, 10: 96
}

const drawNotes: Record<Hole, MidiNote> = {
    1: 62, 2: 67, 3: 71, 4: 74, 5: 77, 6: 81, 7: 83, 8: 86, 9: 89, 10: 93
}

export function noteFor(reed: Reed, key: HarmonicaKey): MidiNote {
    return transposedBy(plainNote(reed), semitonesFromC(key))
}

export function bendableSemitones(reed: Reed): number {
    const bending = plainNote(reed)
    const neighbour = plainNote({ hole: reed.hole, breath: reversed(reed.breath) })
    if (bending <= neighbour) return 0

    return bending - neighbour - 1
}

export function overbendableSemitones(reed: Reed): number {
    const sounding = plainNote(reed)
    const neighbour = plainNote({ hole: reed.hole, breath: reversed(reed.breath) })
    if (sounding >= neighbour) return 0

    return neighbour - sounding + 1
}

function plainNote(reed: Reed): MidiNote {
    return reed.breath === 'blow' ? blowNotes[reed.hole] : drawNotes[reed.hole]
}
