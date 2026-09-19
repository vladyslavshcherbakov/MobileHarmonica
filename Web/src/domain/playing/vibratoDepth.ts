import { quantised } from './controlPrecision.js'

declare const vibratoBrand: unique symbol

export type VibratoDepth = number & { readonly [vibratoBrand]: true }

export const vibratoOff = vibratoDepth(0)

export function vibratoDepth(fraction: number): VibratoDepth {
    return quantised(fraction) as VibratoDepth
}
