export const step = 0.01

export function quantised(value: number, lowest = 0, highest = 1): number {
    if (!Number.isFinite(value)) return 0

    return Math.round(Math.min(highest, Math.max(lowest, value)) / step) * step
}
