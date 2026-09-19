export type HarmonicaPosition = 'first' | 'second' | 'third'

export function semitonesAboveTheHarmonica(position: HarmonicaPosition): number {
    switch (position) {
        case 'first': return 0
        case 'second': return 7
        case 'third': return 2
    }
}
