export type MouthWidth = 1 | 2 | 3 | 4

export const mouthWidths: readonly MouthWidth[] = [1, 2, 3, 4]

export const widestMouth: MouthWidth = 4

export function mouthWidth(holes: number): MouthWidth {
    const within = Math.min(widestMouth, Math.max(1, Math.round(holes)))
    return within as MouthWidth
}
