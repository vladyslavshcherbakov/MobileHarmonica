import type { PositionOnHarmonica } from '../playing/positionOnHarmonica.js'
import { topmostOf } from '../playing/positionOnHarmonica.js'

export type Breath = 'blow' | 'draw'

const slackAcrossTheBoundary = 0.06

export function reversed(breath: Breath): Breath {
    return breath === 'blow' ? 'draw' : 'blow'
}

export function isCrossingTheBreathBoundary(position: PositionOnHarmonica): boolean {
    return Math.abs(position.fractionAboveCentreLine) < slackAcrossTheBoundary
}

export function breathOfTheTopmost(positions: readonly PositionOnHarmonica[]): Breath | null {
    const topmost = topmostOf(positions)
    if (topmost === null) return null

    return topmost.fractionAboveCentreLine >= 0 ? 'blow' : 'draw'
}
