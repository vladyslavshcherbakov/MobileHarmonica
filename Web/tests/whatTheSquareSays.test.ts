import { test } from 'node:test'
import assert from 'node:assert/strict'
import { PlayHarmonica } from '../src/domain/useCases/playHarmonica.js'
import type { PositionOnHarmonica } from '../src/domain/playing/positionOnHarmonica.js'
import { HarmonicaPresenter } from '../src/features/harmonica/harmonicaPresenter.js'
import type { ToneShapingViewState } from '../src/features/harmonica/harmonicaViewState.js'
import { RecordingAudioEngine } from './support/recordingAudioEngine.js'
import { SilentLog } from './support/silentLog.js'

const presenter = new HarmonicaPresenter([])

test('square_whenABlowReedSounds_callsTheUpperAxisTheOverblow', () => {
    assert.equal(shaping(finger(0.25, 0.2))?.overbendLabel, 'overblow ↑', 'hole 3 blown overblows')
})

test('square_whenADrawReedSounds_callsTheUpperAxisTheOverdraw', () => {
    assert.equal(shaping(finger(0.85, -0.3))?.overbendLabel, 'overdraw ↑', 'hole 9 drawn overdraws')
})

test('square_whenNothingSounds_namesNeitherTechnique', () => {
    assert.equal(shaping(null)?.overbendLabel, 'overbend ↑')
})

test('square_whenTheSoundingReedOverbendsButCannotBend_dimsTheBendAlone', () => {
    const state = shaping(finger(0.25, 0.2))

    assert.equal(state?.bendIsAvailable, false)
    assert.equal(state?.overbendIsAvailable, true)
})

test('square_whenTheSoundingReedBendsButCannotOverbend_dimsTheOverbendAlone', () => {
    const state = shaping(finger(0.25, -0.3))

    assert.equal(state?.bendIsAvailable, true, 'hole 3 drawn bends three semitones')
    assert.equal(state?.overbendIsAvailable, false)
})

function shaping(finger: PositionOnHarmonica | null): ToneShapingViewState | undefined {
    const harmonica = new PlayHarmonica(new RecordingAudioEngine(), new SilentLog())
    harmonica.changeMouthWidth(1)
    const state = presenter.present(harmonica.playAt(finger === null ? [] : [finger]), false)
    if (state.kind !== 'ready') return undefined

    return state.playable.toneShaping
}

function finger(fromLeftEdge: number, aboveCentreLine: number): PositionOnHarmonica {
    return { fractionFromLeftEdge: fromLeftEdge, fractionAboveCentreLine: aboveCentreLine }
}
