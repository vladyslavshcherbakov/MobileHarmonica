import type { Score, ScoreEvent } from '../score.js'
import { blow, draw, overblow, rest } from '../scoreWriting.js'

const chug: ScoreEvent[] = [draw([1, 2], 0.667), blow([1, 2], 0.333)]

const chuggedBar: ScoreEvent[] = [...chug, ...chug, ...chug, ...chug]

const openingRiff: ScoreEvent[] = [
    draw(2, 1), draw(3, 1, { bentBy: 1 }),
    blow(4, 0.667), draw(3, 0.333, { bentBy: 1 }), draw(2, 1)
]

const heldTonic: ScoreEvent[] = [draw(2, 3, { vibrato: 0.8 }), rest(1)]

const subdominantStabs: ScoreEvent[] = [
    blow([1, 2, 3], 0.667), rest(0.333),
    blow([1, 2, 3], 0.667), rest(0.333),
    blow(4, 1), blow(5, 1)
]

const subdominantAnswer: ScoreEvent[] = [
    blow(5, 0.667), draw(4, 0.333), blow(4, 1),
    blow([1, 2, 3], 2)
]

const upperFill: ScoreEvent[] = [
    blow(6, 0.5), overblow(6, 0.5), draw(6, 0.5), blow(6, 0.5),
    draw(5, 1, { shakenWith: 6 }), draw(4, 1)
]

const dominantChord: ScoreEvent[] = [
    draw([4, 5, 6], 2), draw(4, 1), draw(5, 1)
]

const subdominantChord: ScoreEvent[] = [
    blow([4, 5, 6], 2), blow(4, 1), draw(3, 1, { bentBy: 1 })
]

const tonicAnswer: ScoreEvent[] = [
    draw(2, 2, { vibrato: 0.8 }), draw(3, 1, { bentBy: 1 }), blow(4, 1)
]

const turnaround: ScoreEvent[] = [
    draw(3, 0.667, { bentBy: 1 }), draw(2, 0.333), draw(1, 1),
    draw([1, 2], 2)
]

export const bluesStrain: Score = {
    name: 'Blues strain',
    key: 'G',
    position: 'second',
    beatsPerMinute: 96,
    events: [
        ...chuggedBar, ...chuggedBar, ...openingRiff, ...heldTonic,
        ...subdominantStabs, ...subdominantAnswer, ...chuggedBar, ...upperFill,
        ...dominantChord, ...subdominantChord, ...tonicAnswer, ...turnaround
    ]
}
