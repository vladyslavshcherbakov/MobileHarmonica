import { quantised } from './controlPrecision.js'

declare const bendBrand: unique symbol

export type BendDepth = number & { readonly [bendBrand]: true }

export const unbent = bendDepth(0)

export function bendDepth(fraction: number): BendDepth {
    return quantised(fraction) as BendDepth
}
