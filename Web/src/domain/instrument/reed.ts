import type { Breath } from './breath.js'
import type { Hole } from './hole.js'

export interface Reed {
    readonly hole: Hole
    readonly breath: Breath
}

export function isSameReed(one: Reed, other: Reed): boolean {
    return one.hole === other.hole && one.breath === other.breath
}
