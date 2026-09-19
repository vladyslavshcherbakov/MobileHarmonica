import type { Score, ScoreEvent } from '../score.js'
import { blow, draw, rest } from '../scoreWriting.js'

const scooped: ScoreEvent[] = [
    draw(3, 2, { bentBy: 2, releasingTo: 0 }),
    blow(4, 1),
    draw(4, 1, { bentBy: 1, releasingTo: 0 }),
    draw(3, 3, { vibrato: 0.8 }),
    rest(1)
]

const answered: ScoreEvent[] = [
    draw(2, 2, { bentBy: 2, releasingTo: 0, vibrato: 0.5 }),
    blow(4, 1),
    draw(4, 1),
    blow(5, 3, { vibrato: 0.6 }),
    rest(1)
]

const climbing: ScoreEvent[] = [
    blow(4, 1, { slideFrom: 2 }),
    draw(4, 1, { bentBy: 1, releasingTo: 0 }),
    blow(5, 1),
    draw(5, 1),
    blow(6, 2, { vibrato: 0.7 }),
    draw(5, 1, { shakenWith: 6 }),
    rest(1)
]

const settling: ScoreEvent[] = [
    draw(4, 1),
    blow(4, 1),
    draw(3, 2, { bentBy: 1, releasingTo: 0 }),
    draw(2, 3, { vibrato: 0.9 }),
    rest(1)
]

export const slowDrag: Score = {
    name: 'Slow drag',
    key: 'G',
    position: 'second',
    beatsPerMinute: 66,
    events: [...scooped, ...answered, ...climbing, ...settling]
}
