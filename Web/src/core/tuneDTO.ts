export interface TuneDTO {
    readonly name: string
    readonly keyPosition: number
    readonly harmonicaKeyPosition: number
    readonly position: 'first' | 'second' | 'third'
    readonly beatsPerMinute: number
    readonly events: readonly ScoreEventDTO[]
}

export interface ScoreEventDTO {
    readonly holes: readonly number[]
    readonly breath: 'blow' | 'draw' | null
    readonly beats: number
    readonly bentBySemitones: number
    readonly isOverbent: boolean
    readonly vibrato: number
    readonly slideFrom: number | null
    readonly shakenWith: number | null
    readonly bendEndsAtSemitones: number | null
}
