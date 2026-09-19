import { quantised } from './controlPrecision.js'

declare const cupBrand: unique symbol

export type CupDepth = number & { readonly [cupBrand]: true }

export const handsOpen = cupDepth(0)

export function cupDepth(fraction: number): CupDepth {
    return quantised(fraction) as CupDepth
}
