export interface RecordedNote {
    readonly start: number
    readonly loopStart: number
    readonly loopEnd: number
    readonly rootHertz: number
    readonly sampleRate: number
}

export interface SampleBank {
    readonly frames: Float32Array
    readonly notes: readonly RecordedNote[]
}
