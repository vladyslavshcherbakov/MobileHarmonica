import type { Score, ScoreEvent } from '../score.js'
import { blow, draw, rest } from '../scoreWriting.js'

const carryingTheWater: ScoreEvent[] = [
    draw(4, 1), draw(4, 1), draw(5, 1),
    draw(5, 1), draw(6, 2, { vibrato: 0.6 }), draw(6, 1),
    blow(6, 1), draw(5, 1), blow(5, 1),
    draw(4, 2, { vibrato: 0.6 })
]

const ivankoFollowing: ScoreEvent[] = [
    draw(4, 1), draw(4, 1), draw(5, 1),
    draw(5, 1), draw(6, 2, { vibrato: 0.6 }), draw(6, 1),
    blow(6, 1), draw(5, 1), blow(5, 1),
    draw(4, 2, { vibrato: 0.6 })
]

export const neseHaliaVodu: Score = {
    name: 'Nese Halia vodu',
    key: 'A',
    position: 'third',
    beatsPerMinute: 80,
    events: [...carryingTheWater, rest(1), ...ivankoFollowing]
}
