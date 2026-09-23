import { test } from 'node:test'
import assert from 'node:assert/strict'
import { HarmonicaPresenter } from '../src/features/harmonica/harmonicaPresenter.js'

const presenter = new HarmonicaPresenter([], false)

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
