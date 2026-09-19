import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loopBoundsIn, midiNumberOf, rootHertzOf } from '../src/audio/recordedHarmonica.js'

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
