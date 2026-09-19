import type { PositionOnHarmonica } from '../playing/positionOnHarmonica.js'
import { isOnTheHarmonica } from '../playing/positionOnHarmonica.js'
import type { MouthWidth } from '../playing/mouthWidth.js'

export type Hole = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10

export const holes: readonly Hole[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

const edgeTolerance = 1e-9

export function holeAt(position: PositionOnHarmonica): Hole | null {
    if (!isOnTheHarmonica(position)) return null

    return holes[nearestIndex(position.fractionFromLeftEdge)] ?? null
}

export function holesCovered(position: PositionOnHarmonica, width: MouthWidth): Hole[] {
    if (!isOnTheHarmonica(position)) return []

    if (width === 1) {
        const single = holeAt(position)
        return single === null ? [] : [single]
    }

    const centre = position.fractionFromLeftEdge * holes.length
    const leftEdge = centre - width / 2
    const rightEdge = centre + width / 2
    return holes.filter((_, index) => isWithin(index + 0.5, leftEdge, rightEdge))
}

function isWithin(centre: number, leftEdge: number, rightEdge: number): boolean {
    return centre >= leftEdge - edgeTolerance && centre < rightEdge - edgeTolerance
}

function nearestIndex(fraction: number): number {
    const withinTheStrip = Math.min(1, Math.max(0, fraction))
    return Math.min(holes.length - 1, Math.floor(withinTheStrip * holes.length))
}
