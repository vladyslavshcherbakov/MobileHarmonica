import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { SoundingHoleDTO, HarmonicaDTO } from '../src/core/harmonicaDTO.js'
import { HarmonicaPresenter } from '../src/features/harmonica/harmonicaPresenter.js'
import type { HarmonicaViewState, HoleViewState } from '../src/features/harmonica/harmonicaViewState.js'

const presenter = new HarmonicaPresenter([], false)

test('noteRow_whenNoHoleSounds_namesNothing', () => {
    const state = presenter.present(harmonica([]), false)

    assert.equal(hole(4, state)?.note, '')
    assert.equal(hole(4, state)?.effect, '')
})

test('noteRow_whenAHoleSounds_namesItsNote', () => {
    const state = presenter.present(harmonica([sounding({ hole: 4, pitch: 72, unbent: 72 })]), false)

    assert.equal(hole(4, state)?.note, 'C5', 'hole 4 blown on a C harmonica is C5')
    assert.equal(hole(4, state)?.effect, '')
})

test('noteRow_whenTheReedIsBent_namesTheBentNoteAndTheReedBehindIt', () => {
    const bent = sounding({ hole: 4, breath: 'draw', pitch: 73, unbent: 74, isShifted: true })

    const state = presenter.present(harmonica([bent]), false)

    assert.equal(hole(4, state)?.note, 'D♭5')
    assert.equal(hole(4, state)?.effect, '(D5 bend)')
})

test('noteRow_whenTheBlowReedIsOverbent_namesTheOverblow', () => {
    const overblown = sounding({ hole: 3, pitch: 72, unbent: 67, isShifted: true, isOverbent: true })

    const state = presenter.present(harmonica([overblown]), false)

    assert.equal(hole(3, state)?.note, 'C5')
    assert.equal(hole(3, state)?.effect, '(G4 overblow)')
})

test('noteRow_whenTheDrawReedIsOverbent_namesTheOverdraw', () => {
    const overdrawn = sounding({
        hole: 9, breath: 'draw', pitch: 92, unbent: 89, isShifted: true, isOverbent: true
    })

    const state = presenter.present(harmonica([overdrawn]), false)

    assert.equal(hole(9, state)?.note, 'A♭6')
    assert.equal(hole(9, state)?.effect, '(F6 overdraw)')
})

test('noteRow_whenAHoleIsBlown_litsTheTopHalf', () => {
    const state = presenter.present(harmonica([sounding({ hole: 1, pitch: 60, unbent: 60 })]), false)

    assert.equal(hole(1, state)?.lit, 'top')
})

test('noteRow_whenAHoleIsDrawn_litsTheBottomHalf', () => {
    const drawn = sounding({ hole: 1, breath: 'draw', pitch: 62, unbent: 62 })

    const state = presenter.present(harmonica([drawn]), false)

    assert.equal(hole(1, state)?.lit, 'bottom')
})

function sounding(hole: Partial<SoundingHoleDTO> & { hole: number }): SoundingHoleDTO {
    return {
        breath: 'blow',
        pitch: 60,
        unbent: 60,
        isShifted: false,
        isOverbent: false,
        ...hole
    }
}

function harmonica(soundingHoles: readonly SoundingHoleDTO[]): HarmonicaDTO {
    return {
        keyPosition: 5,
        style: 'severalFingersSeveralNotes',
        mouthHolesWide: 2,
        cup: 0,
        canBend: false,
        canOverbend: false,
        breath: soundingHoles[0]?.breath ?? null,
        sounding: soundingHoles
    }
}

function hole(number: number, state: HarmonicaViewState): HoleViewState | undefined {
    if (state.kind !== 'ready') return undefined

    return state.playable.holes.find(each => each.id === number)
}
