import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { CoreState, CoreTune } from '../src/core/coreState.js'
import type { HarmonicaCore } from '../src/core/harmonicaCore.js'
import { PlayTheTune } from '../src/features/harmonica/playTheTune.js'

test('tune_whenItIsStopped_leavesTheInstrumentToWhoeverStoppedIt', async () => {
    const core = new RecordingCore()
    const performance = new PlayTheTune(core.asCore(), [tune()], []).play(0, () => {})

    performance.cancel()
    const ending = await performance.finished

    assert.equal(ending, 'stopped')
    assert.deepEqual(core.calls.filter(call => call === 'stopPlaying'), [], 'a finger may be playing by now')
})

test('tune_whenItPlaysToTheEnd_silencesWhatItSounded', async () => {
    const core = new RecordingCore()
    const performance = new PlayTheTune(core.asCore(), [tune()], []).play(0, () => {})

    const ending = await performance.finished

    assert.equal(ending, 'played')
    assert.ok(core.calls.includes('stopPlaying'))
})

class RecordingCore {
    readonly calls: string[] = []

    asCore(): HarmonicaCore {
        return this as unknown as HarmonicaCore
    }

    changeKey(): CoreState {
        return this.record('changeKey')
    }

    play(): CoreState {
        return this.record('play')
    }

    shapeTone(): CoreState {
        return this.record('shapeTone')
    }

    stopPlaying(): CoreState {
        return this.record('stopPlaying')
    }

    private record(call: string): CoreState {
        this.calls.push(call)
        return silent
    }
}

const silent: CoreState = {
    keyPosition: 5,
    style: 'severalFingersSeveralNotes',
    mouthHolesWide: 2,
    cup: 0,
    canBend: false,
    canOverbend: false,
    breath: null,
    sounding: []
}

function tune(): CoreTune {
    return {
        name: 'test',
        keyPosition: 5,
        harmonicaKeyPosition: 5,
        position: 'first',
        beatsPerMinute: 6000,
        events: [
            {
                holes: [4],
                breath: 'draw',
                beats: 1,
                bentBySemitones: 0,
                isOverbent: false,
                vibrato: 0,
                slideFrom: null,
                shakenWith: null,
                bendEndsAtSemitones: null
            }
        ]
    }
}
