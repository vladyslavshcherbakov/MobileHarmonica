declare const sampleRate: number

declare const currentTime: number

declare abstract class AudioWorkletProcessor {
    readonly port: MessagePort

    constructor(options?: { processorOptions?: unknown })

    abstract process(
        inputs: Float32Array[][],
        outputs: Float32Array[][],
        parameters: Record<string, Float32Array>
    ): boolean
}

declare function registerProcessor(
    name: string,
    processor: new (options?: { processorOptions?: unknown }) => AudioWorkletProcessor
): void
