import type { Score, ScoreEvent } from '../score.js'
import { blow, draw, rest } from '../scoreWriting.js'

const underTheCherryTree: ScoreEvent[] = [
    draw(6, 1), draw(6, 1), draw(6, 1),
    blow(6, 1), draw(5, 2, { vibrato: 0.4 }), blow(6, 1),
    blow(6, 1), blow(6, 1), draw(5, 1),
    blow(5, 2, { vibrato: 0.4 })
]

const theOldManStanding: ScoreEvent[] = [
    draw(4, 1), blow(5, 1), draw(5, 1),
    blow(6, 1), draw(6, 2, { vibrato: 0.4 }), draw(6, 1),
    blow(6, 1), draw(5, 1), blow(5, 1),
    draw(4, 2, { vibrato: 0.4 })
]

export const oiPidVyshneiu: Score = {
    name: 'Oi pid vyshneiu',
    key: 'D',
    position: 'third',
    beatsPerMinute: 96,
    events: [...underTheCherryTree, rest(1), ...theOldManStanding]
}
