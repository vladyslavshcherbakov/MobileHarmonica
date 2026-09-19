export interface PositionOnHarmonica {
    readonly fractionFromLeftEdge: number
    readonly fractionAboveCentreLine: number
}

export function topmostOf(positions: readonly PositionOnHarmonica[]): PositionOnHarmonica | null {
    let topmost: PositionOnHarmonica | null = null
    for (const position of positions) {
        if (topmost === null || position.fractionAboveCentreLine > topmost.fractionAboveCentreLine) {
            topmost = position
        }
    }
    return topmost
}

export function isOnTheHarmonica(position: PositionOnHarmonica): boolean {
    return position.fractionFromLeftEdge >= 0 && position.fractionFromLeftEdge <= 1
}
