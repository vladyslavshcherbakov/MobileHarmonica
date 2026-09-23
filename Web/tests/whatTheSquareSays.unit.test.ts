import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { HarmonicaDTO } from '../src/core/harmonicaDTO.js'
import { HarmonicaPresenter } from '../src/features/harmonica/harmonicaPresenter.js'
import type { ToneShapingViewState } from '../src/features/harmonica/harmonicaViewState.js'

const presenter = new HarmonicaPresenter([], false)

test('square_whenABlowReedSounds_callsTheUpperAxisTheOverblow', () => {
    assert.equal(shaping({ breath: 'blow' })?.overbendLabel, 'overblow ↑')
})

test('square_whenADrawReedSounds_callsTheUpperAxisTheOverdraw', () => {
    assert.equal(shaping({ breath: 'draw' })?.overbendLabel, 'overdraw ↑')
})

test('square_whenNothingSounds_namesNeitherTechnique', () => {
    assert.equal(shaping({ breath: null })?.overbendLabel, 'overbend ↑')
})

test('square_whenTheSoundingReedCannotBend_dimsTheBend', () => {
    const state = shaping({ breath: 'blow', canBend: false, canOverbend: true })

    assert.equal(state?.isBendAvailable, false)
    assert.equal(state?.isOverbendAvailable, true)
})

test('square_whenTheSoundingReedCannotOverbend_dimsTheOverbend', () => {
    const state = shaping({ breath: 'draw', canBend: true, canOverbend: false })

    assert.equal(state?.isBendAvailable, true)
    assert.equal(state?.isOverbendAvailable, false)
})

function shaping(of: Partial<HarmonicaDTO>): ToneShapingViewState | undefined {
    const state = presenter.present(harmonica(of), false)
    if (state.kind !== 'ready') return undefined

    return state.playable.toneShaping
}

function harmonica(of: Partial<HarmonicaDTO>): HarmonicaDTO {
    return {
        keyPosition: 5,
        style: 'severalFingersSeveralNotes',
        mouthHolesWide: 2,
        cup: 0,
        canBend: false,
        canOverbend: false,
        breath: null,
        sounding: [],
        ...of
    }
}
