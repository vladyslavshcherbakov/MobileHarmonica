import type { Score, ScoreEvent } from '../score.js'
import { blow, draw, rest } from '../scoreWriting.js'

const hammering: ScoreEvent[] = [
    draw([1, 2], 0.75), blow([1, 2], 0.25),
    draw([1, 2], 0.75), rest(0.25),
    draw([1, 2], 0.75), blow([1, 2], 0.25),
    draw([1, 2], 0.5), rest(0.5)
]

const octaves: ScoreEvent[] = [
    draw([1, 4], 1),
    blow([1, 4], 1),
    draw([1, 4], 0.75), rest(0.25),
    draw(3, 1, { bentBy: 1 })
]

const slapped: ScoreEvent[] = [
    draw([1, 2, 3], 0.15), draw(2, 0.85),
    draw([1, 2, 3], 0.15), draw(3, 0.85, { bentBy: 1 }),
    blow([1, 2, 3], 0.15), blow(4, 0.85),
    draw(2, 0.75, { vibrato: 0.6 }), rest(0.25)
]

const closing: ScoreEvent[] = [
    draw(3, 1, { bentBy: 1, releasingTo: 0 }),
    draw(2, 1),
    draw([1, 2], 2, { vibrato: 0.5 })
]

export const hammerSong: Score = {
    name: 'Hammer song',
    key: 'G',
    position: 'second',
    beatsPerMinute: 104,
    events: [...hammering, ...octaves, ...slapped, ...hammering, ...closing]
}
