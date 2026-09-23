export const holesWideOfTheContact = 0

export interface HarmonicaDTO {
    readonly keyPosition: number
    readonly style: string
    readonly mouthHolesWide: number
    readonly cup: number
    readonly canBend: boolean
    readonly canOverbend: boolean
    readonly breath: 'blow' | 'draw' | null
    readonly sounding: readonly SoundingHoleDTO[]
}

export interface SoundingHoleDTO {
    readonly hole: number
    readonly breath: 'blow' | 'draw'
    readonly pitch: number
    readonly unbent: number
    readonly isShifted: boolean
    readonly isOverbent: boolean
}
