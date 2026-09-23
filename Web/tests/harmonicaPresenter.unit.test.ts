import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { HarmonicaDTO, SoundingHoleDTO } from '../src/core/harmonicaDTO.js'
import { HarmonicaPresenter } from '../src/features/harmonica/harmonicaPresenter.js'
import type {
    HoleViewState,
    NotesPerFingerViewState,
    PlayableHarmonica,
    ShapingPadViewState
} from '../src/features/harmonica/harmonicaViewState.js'

const presenter = new HarmonicaPresenter([], false)
const naturalShapingPadScale = 1

test('unavailableSound_whenNoRecordingIsListed_saysTheRecordingsAreMissing', () => {
    assert.deepEqual(presenter.presentSoundUnavailable({ kind: 'noRecordings' }), {
        kind: 'soundUnavailable',
        text: 'Sound is unavailable: the recordings are not on the page.'
    })
})

test('unavailableSound_whenARecordingCannotBeRead_namesTheRecording', () => {
    assert.deepEqual(presenter.presentSoundUnavailable({ kind: 'recordingUnreadable', recording: 'hrmnca novbA3' }), {
        kind: 'soundUnavailable',
        text: 'Sound is unavailable: the recording hrmnca novbA3 could not be read.'
    })
})

test('unavailableSound_whenTheOutputRefusesToStart_saysSo', () => {
    assert.deepEqual(presenter.presentSoundUnavailable({ kind: 'outputRefused' }), {
        kind: 'soundUnavailable',
        text: 'Sound is unavailable: the audio output would not start.'
    })
})

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

test('noteRow_whenNoHoleSounds_namesNothing', () => {
    const noteRow = hole(4, {})

    assert.equal(noteRow?.note, '')
    assert.equal(noteRow?.effect, '')
})

test('noteRow_whenAHoleSounds_namesItsNote', () => {
    const noteRow = hole(4, soundingAlone({ hole: 4, pitch: 72, unbent: 72 }))

    assert.equal(noteRow?.note, 'C5', 'hole 4 blown on a C harmonica is C5')
    assert.equal(noteRow?.effect, '')
})

test('noteRow_whenTheReedIsBent_namesTheBentNoteAndTheReedBehindIt', () => {
    const noteRow = hole(4, soundingAlone({ hole: 4, breath: 'draw', pitch: 73, unbent: 74, isShifted: true }))

    assert.equal(noteRow?.note, 'D♭5')
    assert.equal(noteRow?.effect, '(D5 bend)')
})

test('noteRow_whenTheBlowReedIsOverbent_namesTheOverblow', () => {
    const noteRow = hole(3, soundingAlone({ hole: 3, pitch: 72, unbent: 67, isShifted: true, isOverbent: true }))

    assert.equal(noteRow?.note, 'C5')
    assert.equal(noteRow?.effect, '(G4 overblow)')
})

test('noteRow_whenTheDrawReedIsOverbent_namesTheOverdraw', () => {
    const noteRow = hole(9, soundingAlone({
        hole: 9, breath: 'draw', pitch: 92, unbent: 89, isShifted: true, isOverbent: true
    }))

    assert.equal(noteRow?.note, 'A♭6')
    assert.equal(noteRow?.effect, '(F6 overdraw)')
})

test('noteRow_whenAHoleIsBlown_litsTheTopHalf', () => {
    assert.equal(hole(1, soundingAlone({ hole: 1, pitch: 60, unbent: 60 }))?.lit, 'top')
})

test('noteRow_whenAHoleIsDrawn_litsTheBottomHalf', () => {
    assert.equal(hole(1, soundingAlone({ hole: 1, breath: 'draw', pitch: 62, unbent: 62 }))?.lit, 'bottom')
})

test('shapingPad_whenTheSoundingReedBends_callsTheUpperHalfTheBend', () => {
    assert.equal(shapingPad({ breath: 'draw', canBend: true })?.pitchLabel, 'bend ↑')
})

test('shapingPad_whenTheSoundingBlowReedOverbends_callsTheUpperHalfTheOverblow', () => {
    assert.equal(shapingPad({ breath: 'blow', canOverbend: true })?.pitchLabel, 'overblow ↑')
})

test('shapingPad_whenTheSoundingDrawReedOverbends_callsTheUpperHalfTheOverdraw', () => {
    assert.equal(shapingPad({ breath: 'draw', canOverbend: true })?.pitchLabel, 'overdraw ↑')
})

test('shapingPad_whenNothingSounds_namesBothTechniquesDimmed', () => {
    const pad = shapingPad({ breath: null })

    assert.equal(pad?.pitchLabel, 'bend · overbend ↑')
    assert.equal(pad?.isPitchShapingAvailable, false)
})

test('shapingPad_whenTheSoundingReedNeitherBendsNorOverbends_dimsThePitchLabel', () => {
    assert.equal(shapingPad({ breath: 'draw' })?.isPitchShapingAvailable, false)
})

function playable(of: Partial<HarmonicaDTO>): PlayableHarmonica | undefined {
    const state = presenter.present(harmonica(of), false, naturalShapingPadScale)
    if (state.kind !== 'ready') return undefined

    return state.playable
}

function notesPerFinger(of: Partial<HarmonicaDTO>): NotesPerFingerViewState | undefined {
    return playable(of)?.notesPerFinger
}

function hole(number: number, of: Partial<HarmonicaDTO>): HoleViewState | undefined {
    return playable(of)?.holes.find(each => each.id === number)
}

function shapingPad(of: Partial<HarmonicaDTO>): ShapingPadViewState | undefined {
    return playable(of)?.shapingPad
}

function soundingAlone(reed: Partial<SoundingHoleDTO> & { hole: number }): Partial<HarmonicaDTO> {
    const sounding: SoundingHoleDTO = {
        breath: 'blow',
        pitch: 60,
        unbent: 60,
        isShifted: false,
        isOverbent: false,
        ...reed
    }
    return { breath: sounding.breath, sounding: [sounding] }
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
