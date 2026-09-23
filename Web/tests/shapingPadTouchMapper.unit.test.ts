import { test } from 'node:test'
import assert from 'node:assert/strict'
import { ShapingPadTouchMapper } from '../src/features/harmonica/touch/shapingPadTouchMapper.js'

const shapingPad = { width: 100, height: 100 }

test('shapingPad_whenTheThumbIsAtTheTopRight_shapesThePitchFullyWithFullVibrato', () => {
    assert.deepEqual(new ShapingPadTouchMapper([{ x: 100, y: 0, force: null }], shapingPad).shaping(), { pitch: 1, vibrato: 1 })
})

test('shapingPad_whenTheThumbIsAtTheBottomLeft_isAsFarBelowTheMiddleAsItGoesWithNoVibrato', () => {
    assert.deepEqual(new ShapingPadTouchMapper([{ x: 0, y: 100, force: null }], shapingPad).shaping(), { pitch: -1, vibrato: 0 })
})

test('shapingPad_whenTwoFingersPinch_shapesNothing', () => {
    assert.equal(new ShapingPadTouchMapper([{ x: 10, y: 10, force: null }, { x: 90, y: 90, force: null }], shapingPad).shaping(), null)
})
