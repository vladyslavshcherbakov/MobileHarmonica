import type { PositionOnHarmonica } from './positionOnHarmonica.js'
import { quantised } from './controlPrecision.js'

declare const intensityBrand: unique symbol

export type BreathIntensity = number & { readonly [intensityBrand]: true }

export const gainOnTheCentreLine = 0.2

const distanceAtFullPressure = 0.5

export const fullPressure = breathIntensity(1)

export function breathIntensity(gain: number): BreathIntensity {
    return gain as BreathIntensity
}

export function intensityAt(position: PositionOnHarmonica): BreathIntensity {
    const pressed = Math.min(1, Math.abs(position.fractionAboveCentreLine) / distanceAtFullPressure)
    const headroom = 1 - gainOnTheCentreLine
    return quantised(gainOnTheCentreLine + headroom * (1 - Math.pow(1 - pressed, 2))) as BreathIntensity
}
