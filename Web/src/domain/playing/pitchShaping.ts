import type { BendDepth } from './bendDepth.js'
import { bendDepth } from './bendDepth.js'
import type { OverbendDepth } from './overbendDepth.js'
import { overbendDepth } from './overbendDepth.js'
import { quantised } from './controlPrecision.js'

declare const shapingBrand: unique symbol

export type PitchShaping = number & { readonly [shapingBrand]: true }

const overbendThreshold = 0.5

export const restingShaping = pitchShaping(0)

export function pitchShaping(fraction: number): PitchShaping {
    return quantised(fraction, -1, 1) as PitchShaping
}

export function bendOf(shaping: PitchShaping): BendDepth {
    return bendDepth(-shaping)
}

export function overbendOf(shaping: PitchShaping): OverbendDepth {
    return overbendDepth(shaping < overbendThreshold ? 0 : 1)
}
