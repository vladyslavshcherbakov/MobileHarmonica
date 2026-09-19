import type { Score, ScoreEvent } from '../score.js'
import { blow, draw, rest } from '../scoreWriting.js'

const callingOverTheFire: ScoreEvent[] = [
    blow(6, 1), blow(6, 1), draw(5, 1),
    blow(5, 1), draw(4, 2, { vibrato: 0.5 }), blow(4, 1),
    draw(4, 1), blow(5, 1), draw(5, 1),
    blow(6, 2, { vibrato: 0.5 })
]

const theAnswerBack: ScoreEvent[] = [
    blow(6, 1), draw(6, 1), blow(6, 1),
    draw(5, 1), blow(5, 2, { vibrato: 0.5 }), draw(4, 1),
    blow(5, 1), draw(4, 1), blow(4, 1),
    blow(4, 2, { vibrato: 0.5 })
]

export const naIvanaNaKupala: Score = {
    name: 'Na Ivana na Kupala',
    key: 'G',
    position: 'first',
    beatsPerMinute: 104,
    events: [...callingOverTheFire, rest(1), ...theAnswerBack]
}
