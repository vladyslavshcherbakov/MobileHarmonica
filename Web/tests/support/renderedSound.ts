import type { ReedSampler } from '../../src/audio/harmonicaWorklet.js'

export const sampleRate = 48000
export const framesPerBuffer = 960

export function frequencyOf(sampler: ReedSampler): number {
    return risingEdgeFrequency(buffer(sampler))
}

export function loudnessOf(sampler: ReedSampler): number {
    return rootMeanSquare(buffer(sampler))
}

export function settle(sampler: ReedSampler): void {
    render(3, sampler)
}

export function render(buffers: number, sampler: ReedSampler): void {
    for (let index = 0; index < buffers; index += 1) {
        buffer(sampler)
    }
}

function buffer(sampler: ReedSampler): Float32Array {
    const samples = new Float32Array(framesPerBuffer)
    sampler.render(samples, 1)
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
