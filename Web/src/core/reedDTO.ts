export interface ReedDTO {
    readonly hole: number
    readonly breath: 'blow' | 'draw'
    readonly bendableSemitones: number
    readonly overbendableSemitones: number
}
