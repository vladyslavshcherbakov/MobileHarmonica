import type { Score, ScoreEvent } from '../score.js'
import { blow, draw, rest } from '../scoreWriting.js'

const horn: ScoreEvent[] = [
    blow([1, 2, 3], 1.5),
    blow([1, 2, 3], 0.5),
    blow([1, 2, 3], 2, { vibrato: 0.7 }),
    rest(1)
]

const gallop: ScoreEvent[] = [
    draw([1, 2], 0.333), draw([1, 2], 0.333), blow([1, 2], 0.334),
    draw([1, 2], 0.333), draw([1, 2], 0.333), blow([1, 2], 0.334),
    draw([1, 2], 0.333), draw([1, 2], 0.333), blow([1, 2], 0.334),
    draw([1, 2], 0.333), draw([1, 2], 0.333), blow([1, 2], 0.334)
]

const whooping: ScoreEvent[] = [
    draw(4, 1, { shakenWith: 5 }),
    draw(5, 1, { shakenWith: 6 }),
    draw(2, 1, { bentBy: 2, releasingTo: 0 }),
    draw(3, 1, { bentBy: 3, releasingTo: 0 })
]

const baying: ScoreEvent[] = [
    draw(4, 1.5, { shakenWith: 5 }),
    draw(3, 1, { bentBy: 3, releasingTo: 1 }),
    draw(2, 1.5, { bentBy: 2, vibrato: 0.9 }),
    rest(2)
]

export const foxChase: Score = {
    name: 'Fox chase',
    key: 'G',
    position: 'second',
    beatsPerMinute: 132,
    events: [...horn, ...gallop, ...whooping, ...gallop, ...baying]
}
