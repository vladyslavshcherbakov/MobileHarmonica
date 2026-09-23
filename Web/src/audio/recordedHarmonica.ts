import type { RecordedNote, SampleBank } from './sampleBank.js'
import type { Log } from '../logging/log.js'
import { RecordingError } from './recordingError.js'

const indexName = 'index.json'
const loopStartSeconds = 1
const loopEndSeconds = 4
const shortestLoopSeconds = 0.2
const loopCrossfadeSeconds = 0.15
const semitonesAboveTheLabel = 12
const concertPitchHertz = 440
const concertPitchNumber = 69
const semitonesAboveC: Record<string, number> = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 }

export async function recordedHarmonica(
    folder: string,
    context: BaseAudioContext,
    log: Log
): Promise<SampleBank> {
    const names = await namesIn(folder)
    if (names.length === 0) throw new RecordingError('notListed', folder, `no recordings listed in ${folder}/${indexName}`)

    log.record(`${indexName} lists ${names.length} recordings`)
    let decodedCount = 0
    const recordings = await Promise.all(names.map(async name => {
        const recording = await read(folder, name, context, log)
        decodedCount += 1
        log.record(`decoded ${decodedCount} of ${names.length}`)
        return recording
    }))
    return assembled(recordings)
}

export function rootHertzOf(name: string): number {
    const number = midiNumberOf(name)
    if (number === null) throw new RecordingError('unreadable', name, `${name} does not end in a pitch`)

    return concertPitchHertz * Math.pow(2, (number + semitonesAboveTheLabel - concertPitchNumber) / 12)
}

export function loopBoundsIn(frameCount: number, framesPerSecond: number, name: string): [number, number] {
    const start = Math.round(loopStartSeconds * framesPerSecond)
    const end = Math.min(frameCount, Math.round(loopEndSeconds * framesPerSecond))
    if (end - start < shortestLoopSeconds * framesPerSecond) {
        throw new RecordingError(
            'unreadable',
            name,
            `${name} is ${(frameCount / framesPerSecond).toFixed(2)} seconds, too short to loop`
        )
    }

    return [start, end]
}

export function withASmoothedLoop(
    frames: Float32Array,
    loopStart: number,
    loopEnd: number,
    framesPerSecond: number
): Float32Array {
    const width = Math.min(
        Math.round(loopCrossfadeSeconds * framesPerSecond),
        loopStart,
        loopEnd - loopStart
    )
    if (width < 2) return frames

    for (let step = 0; step < width; step += 1) {
        const angle = (0.5 * Math.PI * step) / (width - 1)
        const leaving = frames[loopEnd - width + step] as number
        const arriving = frames[loopStart - width + step] as number
        frames[loopEnd - width + step] = leaving * Math.cos(angle) + arriving * Math.sin(angle)
    }
    return frames
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
    if (!listing.ok) throw new RecordingError('notListed', folder, `${folder}/${indexName} answered ${listing.status}`)

    const listed = (await listing.json()) as { samples?: unknown }
    return Array.isArray(listed.samples) ? listed.samples.filter(name => typeof name === 'string') : []
}

async function read(
    folder: string,
    name: string,
    context: BaseAudioContext,
    log: Log
): Promise<Recording> {
    const file = await fetch(`${folder}/${encodeURIComponent(name)}`)
    if (!file.ok) throw new RecordingError('unreadable', name, `${name} answered ${file.status}`)

    const decoded = await decode(await file.arrayBuffer(), name, context)
    log.recordSample(`${name} decoded, ${decoded.length} frames at ${decoded.sampleRate} Hz`)
    const recordingName = withoutTheExtension(name)
    const [loopStart, loopEnd] = loopBoundsIn(decoded.length, decoded.sampleRate, recordingName)
    const framesWithABlendedTail = withASmoothedLoop(mono(decoded), loopStart, loopEnd, decoded.sampleRate)
    const frames = framesWithABlendedTail.subarray(0, loopEnd)
    const rootHertz = rootHertzOf(recordingName)
    return {
        frames,
        note: start => ({ start, loopStart, loopEnd, rootHertz, sampleRate: decoded.sampleRate })
    }
}

async function decode(file: ArrayBuffer, name: string, context: BaseAudioContext): Promise<AudioBuffer> {
    try {
        return await context.decodeAudioData(file)
    } catch (failure) {
        throw new RecordingError('unreadable', name, `${name} could not be decoded: ${String(failure)}`)
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
