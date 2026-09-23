import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { HarmonicaDTO } from '../src/core/harmonicaDTO.js'
import type { TuneDTO } from '../src/core/tuneDTO.js'
import { PlayTheTuneUseCase } from '../src/features/harmonica/playTheTuneUseCase.js'
import { TestEnvironment, withoutTheBuiltCore } from './support/testEnvironment.js'

test('tune_whenItPlaysToTheEnd_leavesNothingSounding', { skip: withoutTheBuiltCore }, async () => {
    const core = await new TestEnvironment().core()
    const reported: HarmonicaDTO[] = []

    const ending = await new PlayTheTuneUseCase(core, [oneNote()], core.reeds(), core.timing())
        .play(0, state => reported.push(state))
        .finished

    assert.equal(ending, 'played')
    assert.deepEqual(reported[reported.length - 1]?.sounding, [])
})

test('tune_whenItIsNotThere_isRefusedNamingIt', { skip: withoutTheBuiltCore }, async () => {
    const core = await new TestEnvironment().core()

    const performance = new PlayTheTuneUseCase(core, [], core.reeds(), core.timing()).play(3, () => {})

    await performance.finished.then(
        () => assert.ok(false, 'a tune that is not there cannot have played'),
        (failure: unknown) => assert.equal(String(failure), 'Error: there is no tune 3')
    )
})

function oneNote(): TuneDTO {
    return {
        name: 'one note',
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
