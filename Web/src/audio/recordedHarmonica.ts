import type { RecordedNote, SampleBank } from './sampleBank.js'

const indexName = 'index.json'
const loopStartSeconds = 1
const loopEndSeconds = 4
const shortestLoopSeconds = 0.2
const semitonesAboveTheLabel = 12
const concertPitchHertz = 440
const concertPitchNumber = 69
const semitonesAboveC: Record<string, number> = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 }

export async function recordedHarmonica(folder: string, context: BaseAudioContext): Promise<SampleBank> {
    const names = await namesIn(folder)
    if (names.length === 0) throw new Error(`no recordings listed in ${folder}/${indexName}`)

    const recordings = await Promise.all(names.map(name => read(folder, name, context)))
    return assembled(recordings)
}

export function rootHertzOf(name: string): number {
    const number = midiNumberOf(name)
    if (number === null) throw new Error(`${name} does not end in a pitch`)

    return concertPitchHertz * Math.pow(2, (number + semitonesAboveTheLabel - concertPitchNumber) / 12)
}

export function loopBoundsIn(frameCount: number, framesPerSecond: number, name: string): [number, number] {
    const start = Math.round(loopStartSeconds * framesPerSecond)
    const end = Math.min(frameCount, Math.round(loopEndSeconds * framesPerSecond))
    if (end - start < shortestLoopSeconds * framesPerSecond) {
        throw new Error(`${name} is ${(frameCount / framesPerSecond).toFixed(2)} seconds, too short to loop`)
    }

    return [start, end]
}

export function midiNumberOf(name: string): number | null {
    const pitch = /([A-G])(#?)(-?\d)$/.exec(name)
    if (pitch === null) return null

    const semitones = semitonesAboveC[pitch[1] as string]
    if (semitones === undefined) return null

    return semitones + (pitch[2] === '#' ? 1 : 0) + 12 * (Number(pitch[3]) + 1)
}

interface Recording {
    readonly frames: Float32Array
    readonly note: (start: number) => RecordedNote
}

async function namesIn(folder: string): Promise<string[]> {
    const listing = await fetch(`${folder}/${indexName}`)
    if (!listing.ok) throw new Error(`${folder}/${indexName} answered ${listing.status}`)

    const listed = (await listing.json()) as { samples?: unknown }
    return Array.isArray(listed.samples) ? listed.samples.filter(name => typeof name === 'string') : []
}

async function read(folder: string, name: string, context: BaseAudioContext): Promise<Recording> {
    const file = await fetch(`${folder}/${encodeURIComponent(name)}`)
    if (!file.ok) throw new Error(`${name} answered ${file.status}`)

    const decoded = await context.decodeAudioData(await file.arrayBuffer())
    const played = withoutTheExtension(name)
    const [loopStart, loopEnd] = loopBoundsIn(decoded.length, decoded.sampleRate, played)
    const frames = mono(decoded).subarray(0, loopEnd)
    const rootHertz = rootHertzOf(played)
    return {
        frames,
        note: start => ({ start, loopStart, loopEnd, rootHertz, sampleRate: decoded.sampleRate })
    }
}

function mono(decoded: AudioBuffer): Float32Array {
    const mixed = new Float32Array(decoded.length)
    for (let channel = 0; channel < decoded.numberOfChannels; channel += 1) {
        const source = decoded.getChannelData(channel)
        for (let frame = 0; frame < mixed.length; frame += 1) {
            mixed[frame] = (mixed[frame] as number) + (source[frame] as number) / decoded.numberOfChannels
        }
    }
    return mixed
}

function assembled(recordings: readonly Recording[]): SampleBank {
    const frames = new Float32Array(recordings.reduce((count, each) => count + each.frames.length, 0))
    const notes: RecordedNote[] = []
    let start = 0
    for (const recording of recordings) {
        frames.set(recording.frames, start)
        notes.push(recording.note(start))
        start += recording.frames.length
    }
    return { frames, notes }
}

function withoutTheExtension(name: string): string {
    return name.replace(/\.wav$/i, '')
}
