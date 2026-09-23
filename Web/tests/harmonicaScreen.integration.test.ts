import { test } from 'node:test'
import assert from 'node:assert/strict'
import { AudioEngineFailure } from '../src/core/audioEngine.js'
import { TestEnvironment, withoutTheBuiltCore } from './support/testEnvironment.js'

test('harmonicaScreen_whenTheCoreStarts_showsTenHolesInC', { skip: withoutTheBuiltCore }, async () => {
    const screen = await new TestEnvironment().harmonicaScreen()

    assert.equal(screen.state.kind === 'ready' ? screen.state.playable.holes.length : 0, 10)
    assert.equal(screen.state.kind === 'ready' ? screen.state.playable.key.label : '', 'C')
})

test('strip_whenAFingerIsOnHoleFourAboveTheLine_soundsAndNamesC5', { skip: withoutTheBuiltCore }, async () => {
    const environment = new TestEnvironment()
    const screen = await environment.harmonicaScreen()

    screen.touchStrip(0.35, 0.2)

    assert.equal(screen.note(4), 'C5')
    assert.ok(Math.abs(environment.audio.hertzOfTheLastTone - 523.25) < 0.5, 'hole 4 blows C5')
})

test('shapingPad_whenTheFingerIsAtTheTopOverABendingReed_bendsIt', { skip: withoutTheBuiltCore }, async () => {
    const screen = await new TestEnvironment().harmonicaScreen()
    screen.touchStrip(0.35, -0.3)

    screen.touchShapingPad(1, 0)

    assert.equal(screen.note(4), 'D♭5', 'hole 4 draw bends one semitone')
})

test('shapingPad_whenAFingerBelowTheMiddleMeetsABendingReed_leavesItUnbent', { skip: withoutTheBuiltCore }, async () => {
    const screen = await new TestEnvironment().harmonicaScreen()
    screen.touchShapingPad(-0.8, 0.7)

    screen.touchStrip(0.35, -0.3)

    assert.equal(screen.note(4), 'D5', 'the lower half of the pad carries vibrato and never bends')
})

test('demo_whenAFingerTakesOverFromATune_leavesTheFingersNoteSounding', { skip: withoutTheBuiltCore }, async () => {
    const environment = new TestEnvironment()
    const screen = await environment.harmonicaScreen()
    screen.playTune(0)

    screen.touchStrip(0.35, 0.2)

    const stopped = await until(() => environment.log.lines.includes('the tune was stopped'))
    assert.ok(stopped, 'the tune says it stopped')
    assert.deepEqual(environment.audio.releases, [], 'a stopped tune does not damp what the finger sounds')
    assert.ok(Math.abs(environment.audio.hertzOfTheLastTone - 523.25) < 0.5, 'hole 4 blown is still what is heard')
})

test('harmonicaScreen_whenTheAudioCannotStart_saysSoundIsUnavailable', { skip: withoutTheBuiltCore }, async () => {
    const environment = new TestEnvironment()
    environment.audio.preparationFailure = new AudioEngineFailure({ kind: 'outputRefused' }, 'NotAllowedError')

    const screen = await environment.harmonicaScreen()

    assert.equal(screen.state.kind, 'soundUnavailable')
})

test('strip_whenTheSoundIsUnavailable_soundsNothing', { skip: withoutTheBuiltCore }, async () => {
    const environment = new TestEnvironment()
    environment.audio.preparationFailure = new AudioEngineFailure({ kind: 'noRecordings' }, 'index.json answered 404')
    const screen = await environment.harmonicaScreen()

    screen.touchStrip(0.35, 0.2)

    assert.deepEqual(environment.audio.soundedTones, [])
})

async function until(condition: () => boolean): Promise<boolean> {
    for (let look = 0; look < 600; look += 1) {
        if (condition()) return true

        await new Promise(resolve => setTimeout(resolve, 5))
    }
    return condition()
}
