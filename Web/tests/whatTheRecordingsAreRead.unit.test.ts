import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loopBoundsIn, midiNumberOf, rootHertzOf, withASmoothedLoop } from '../src/audio/recordedHarmonica.js'

test('recording_whenItsNameEndsInAPitch_soundsAnOctaveAboveTheLabel', () => {
    assert.ok(
        Math.abs(rootHertzOf('hrmnca novbA2') - 220) < 0.01,
        'the library labels an octave below concert pitch, so A2 is A3'
    )
})

test('recording_whenItsNameCarriesASharp_readsTheSharp', () => {
    assert.equal(midiNumberOf('hrmnca novbC#3'), 49)
    assert.ok(Math.abs(rootHertzOf('hrmnca novbC#3') - 277.18) < 0.01)
})

test('recording_whenItsNameEndsInNoPitch_isRefused', () => {
    assert.equal(midiNumberOf('hrmnca novb'), null)
    assert.throws(() => rootHertzOf('hrmnca novb'), /does not end in a pitch/)
})

test('loop_whenTheRecordingIsLongEnough_isSecondsOneToFour', () => {
    assert.deepEqual(loopBoundsIn(11 * 44100, 44100, 'long enough'), [44100, 176400])
})

test('loop_whenTheRecordingRunsOutEarly_endsWhereTheFramesDo', () => {
    assert.deepEqual(loopBoundsIn(Math.round(2.5 * 44100), 44100, 'cut short'), [44100, 110250])
})

test('loop_whenTheRecordingIsTooShortToHoldOne_namesItself', () => {
    assert.throws(() => loopBoundsIn(Math.round(1.1 * 44100), 44100, 'hrmnca novbA2'), /hrmnca novbA2/)
})

test('loop_whenItWraps_arrivesFromWhereItLeftOff', () => {
    const rate = 44100
    const [loopStart, loopEnd] = [rate, 4 * rate]
    const played = withASmoothedLoop(recordedTone(loopEnd, rate), loopStart, loopEnd, rate)

    const wrap = Math.abs((played[loopStart] as number) - (played[loopEnd - 1] as number))
    const ordinary = Math.abs((played[loopStart] as number) - (played[loopStart - 1] as number))
    assert.ok(wrap <= ordinary * 1.001, `the wrap steps ${wrap}, an ordinary frame steps ${ordinary}`)
})

test('loop_whenTheRecordingCannotSpareACrossfade_isLeftAlone', () => {
    const frames = recordedTone(100, 44100)
    const before = Array.from(frames)

    assert.deepEqual(Array.from(withASmoothedLoop(frames, 1, 100, 44100)), before)
})

function recordedTone(frameCount: number, framesPerSecond: number): Float32Array {
    const frames = new Float32Array(frameCount)
    for (let frame = 0; frame < frameCount; frame += 1) {
        const seconds = frame / framesPerSecond
        frames[frame] = Math.sin(2 * Math.PI * 220 * seconds) * Math.exp(-seconds / 8)
    }
    return frames
}
