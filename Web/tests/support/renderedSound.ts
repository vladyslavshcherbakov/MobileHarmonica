import type { Oscillator } from '../../src/audio/harmonicaWorklet.js'

export const sampleRate = 48000
export const framesPerBuffer = 960

export function frequencyOf(oscillator: Oscillator): number {
    return risingEdgeFrequency(buffer(oscillator))
}

export function loudnessOf(oscillator: Oscillator): number {
    return rootMeanSquare(buffer(oscillator))
}

export function settle(oscillator: Oscillator): void {
    render(3, oscillator)
}

export function render(buffers: number, oscillator: Oscillator): void {
    for (let index = 0; index < buffers; index += 1) {
        buffer(oscillator)
    }
}

function buffer(oscillator: Oscillator): Float32Array {
    const samples = new Float32Array(framesPerBuffer)
    oscillator.render(samples, 1)
    return samples
}

function rootMeanSquare(samples: Float32Array): number {
    let squares = 0
    for (const sample of samples) squares += sample * sample

    return Math.sqrt(squares / samples.length)
}

function risingEdgeFrequency(samples: Float32Array): number {
    const edges = risingEdges(samples)
    const first = edges[0]
    const last = edges[edges.length - 1]
    if (first === undefined || last === undefined || edges.length < 2) return 0

    return (sampleRate * (edges.length - 1)) / (last - first)
}

function risingEdges(samples: Float32Array): number[] {
    const edges: number[] = []
    for (let frame = 1; frame < samples.length; frame += 1) {
        if ((samples[frame - 1] ?? 0) <= 0 && (samples[frame] ?? 0) > 0) edges.push(frame)
    }
    return edges
}
