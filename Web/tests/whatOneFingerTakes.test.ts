import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { CoreState } from '../src/core/coreState.js'
import { HarmonicaPresenter } from '../src/features/harmonica/harmonicaPresenter.js'
import type { NotesPerFingerViewState } from '../src/features/harmonica/harmonicaViewState.js'

const presenter = new HarmonicaPresenter([])

test('notesPerFinger_whenEveryFingerTakesSeveralNotes_offersWhatWasChosen', () => {
    const notes = notesPerFinger({ style: 'severalFingersSeveralNotes', mouthHolesWide: 3 })

    assert.equal(notes?.chosen, 3)
    assert.equal(notes?.isAvailable, true)
})

test('notesPerFinger_whenOneFingerTakesSeveralNotes_offersWhatWasChosen', () => {
    const notes = notesPerFinger({ style: 'oneFingerSeveralNotes', mouthHolesWide: 4 })

    assert.equal(notes?.chosen, 4)
    assert.equal(notes?.isAvailable, true)
})

test('notesPerFinger_whenAFingerTakesOneNote_saysOneAndIsNotOffered', () => {
    const notes = notesPerFinger({ style: 'severalFingersOneNote', mouthHolesWide: 4 })

    assert.equal(notes?.chosen, 1, 'the style allows one note, so the control cannot say four')
    assert.equal(notes?.isAvailable, false)
})

test('notesPerFinger_whateverIsChosen_isCountedInNotes', () => {
    assert.deepEqual(notesPerFinger({})?.choices, [
        { count: 1, name: '1 note' },
        { count: 2, name: '2 notes' },
        { count: 3, name: '3 notes' },
        { count: 4, name: '4 notes' }
    ])
})

function notesPerFinger(of: Partial<CoreState>): NotesPerFingerViewState | undefined {
    const state = presenter.present(harmonica(of), false)
    if (state.kind !== 'ready') return undefined

    return state.playable.notesPerFinger
}

function harmonica(of: Partial<CoreState>): CoreState {
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
