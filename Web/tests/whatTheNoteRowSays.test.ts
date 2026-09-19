import { test } from 'node:test'
import assert from 'node:assert/strict'
import { PlayHarmonica } from '../src/domain/useCases/playHarmonica.js'
import { pitchShaping } from '../src/domain/playing/pitchShaping.js'
import { vibratoOff } from '../src/domain/playing/vibratoDepth.js'
import type { PositionOnHarmonica } from '../src/domain/playing/positionOnHarmonica.js'
import { HarmonicaPresenter } from '../src/features/harmonica/harmonicaPresenter.js'
import type { HarmonicaViewState, HoleViewState } from '../src/features/harmonica/harmonicaViewState.js'
import { RecordingAudioEngine } from './support/recordingAudioEngine.js'
import { SilentLog } from './support/silentLog.js'

const presenter = new HarmonicaPresenter([])

test('noteRow_whenNoHoleSounds_namesNothing', () => {
    const harmonica = playing()

    const state = presenter.present(harmonica.playAt([]), false)

    assert.equal(hole(4, state)?.note, '')
    assert.equal(hole(4, state)?.effect, '')
})

test('noteRow_whenTheFingerIsAboveTheLine_namesTheBlowReed', () => {
    const harmonica = playing()

    const state = presenter.present(harmonica.playAt([finger(0.35, 0.2)]), false)

    assert.equal(hole(4, state)?.note, 'C5')
})

test('noteRow_whenTheFingerIsBelowTheLine_namesTheDrawReed', () => {
    const harmonica = playing()

    const state = presenter.present(harmonica.playAt([finger(0.35, -0.3)]), false)

    assert.equal(hole(4, state)?.note, 'D5')
})

test('noteRow_whenTheDrawReedIsBentToItsLimit_namesTheBentNoteAndTheReedBehindIt', () => {
    const harmonica = playing()
    harmonica.playAt([finger(0.35, -0.3)])

    const state = presenter.present(harmonica.shapeTone(pitchShaping(-1), vibratoOff), false)

    assert.equal(hole(4, state)?.note, 'D♭5')
    assert.equal(hole(4, state)?.effect, '(D5 bend)')
})

test('noteRow_whenTheBlowReedIsOverbent_namesTheOverblow', () => {
    const harmonica = playing()
    harmonica.playAt([finger(0.25, 0.2)])

    const state = presenter.present(harmonica.shapeTone(pitchShaping(1), vibratoOff), false)

    assert.equal(hole(3, state)?.note, 'C5')
    assert.equal(hole(3, state)?.effect, '(G4 overblow)')
})

test('noteRow_whenTheDrawReedIsOverbent_namesTheOverdraw', () => {
    const harmonica = playing()
    harmonica.playAt([finger(0.85, -0.3)])

    const state = presenter.present(harmonica.shapeTone(pitchShaping(1), vibratoOff), false)

    assert.equal(hole(9, state)?.note, 'A♭6')
    assert.equal(hole(9, state)?.effect, '(F6 overdraw)')
})

test('noteRow_whenTheBendRoundsToNoSemitone_namesOnlyTheNote', () => {
    const harmonica = playing()
    harmonica.playAt([finger(0.25, -0.3)])

    const state = presenter.present(harmonica.shapeTone(pitchShaping(-0.1), vibratoOff), false)

    assert.equal(hole(3, state)?.note, 'B4')
    assert.equal(hole(3, state)?.effect, '')
})

test('noteRow_whenTheKeyIsD_namesTheReedInThatKey', () => {
    const harmonica = playing()
    harmonica.playAt([finger(0.05, 0.2)])

    const state = presenter.present(harmonica.changeKey('D'), false)

    assert.equal(hole(1, state)?.note, 'D4')
})

function playing(): PlayHarmonica {
    const harmonica = new PlayHarmonica(new RecordingAudioEngine(), new SilentLog())
    harmonica.changeMouthWidth(1)
    return harmonica
}

function finger(fromLeftEdge: number, aboveCentreLine: number): PositionOnHarmonica {
    return { fractionFromLeftEdge: fromLeftEdge, fractionAboveCentreLine: aboveCentreLine }
}

function hole(number: number, state: HarmonicaViewState): HoleViewState | undefined {
    if (state.kind !== 'ready') return undefined

    return state.playable.holes.find(each => each.id === number)
}
