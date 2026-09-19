import { quantised } from './controlPrecision.js'

declare const overbendBrand: unique symbol

export type OverbendDepth = number & { readonly [overbendBrand]: true }

export const noOverbend = overbendDepth(0)

export function overbendDepth(fraction: number): OverbendDepth {
    return quantised(fraction) as OverbendDepth
}
