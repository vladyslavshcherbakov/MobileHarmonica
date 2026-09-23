import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { FingerMarksViewState } from '../src/features/harmonica/harmonicaViewState.js'
import { SquareTouchMapper } from '../src/features/harmonica/touch/squareTouchMapper.js'
import { StripTouchMapper } from '../src/features/harmonica/touch/stripTouchMapper.js'

const strip = { width: 1000, height: 100 }
const square = { width: 100, height: 100 }
const everyFingerAtRest: FingerMarksViewState = { width: { kind: 'resting' }, drawsOnlyTheDecidingFinger: false }

test('stripMarks_whenAFingerHasSlidOffTheStrip_drawsOnlyTheOneStillOnIt', () => {
    const marks = new StripTouchMapper([{ x: 350, y: 30, force: null }, { x: 1200, y: 10, force: null }], strip).marks(everyFingerAtRest)

    assert.deepEqual(marks, [{ x: 350, y: 30, diameter: 56, isTheDecidingFinger: true }])
})

test('stripMarks_whenOneFingerCounts_drawsTheTopmostAlone', () => {
    const drawn: FingerMarksViewState = { width: { kind: 'resting' }, drawsOnlyTheDecidingFinger: true }

    const marks = new StripTouchMapper([{ x: 350, y: 60, force: null }, { x: 550, y: 20, force: null }], strip).marks(drawn)

    assert.deepEqual(marks, [{ x: 550, y: 20, diameter: 56, isTheDecidingFinger: true }])
})

test('stripMarks_whenTheCircleSpansTheMouth_isAsWideAsTheHolesItCovers', () => {
    const drawn: FingerMarksViewState = { width: { kind: 'holesWide', holes: 3 }, drawsOnlyTheDecidingFinger: false }

    const marks = new StripTouchMapper([{ x: 350, y: 30, force: null }], strip).marks(drawn)

    assert.equal(marks[0]?.diameter, 300, 'three holes of a strip ten holes across 1000 points')
})

test('squareShaping_whenTheThumbIsAtTheTopRight_overbendsWithFullVibrato', () => {
    assert.deepEqual(new SquareTouchMapper([{ x: 100, y: 0, force: null }], square).shaping(), { pitch: 1, vibrato: 1 })
})

test('squareShaping_whenTheThumbIsAtTheBottomLeft_bendsFullyWithNoVibrato', () => {
    assert.deepEqual(new SquareTouchMapper([{ x: 0, y: 100, force: null }], square).shaping(), { pitch: -1, vibrato: 0 })
})

test('squareShaping_whenTwoFingersPinch_shapesNothing', () => {
    assert.equal(new SquareTouchMapper([{ x: 10, y: 10, force: null }, { x: 90, y: 90, force: null }], square).shaping(), null)
})
