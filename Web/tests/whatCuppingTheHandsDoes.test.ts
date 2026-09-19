import { test } from 'node:test'
import assert from 'node:assert/strict'
import { PlayHarmonica } from '../src/domain/useCases/playHarmonica.js'
import { cupDepth } from '../src/domain/playing/cupDepth.js'
import { HarmonicaPresenter } from '../src/features/harmonica/harmonicaPresenter.js'
import { RecordingAudioEngine } from './support/recordingAudioEngine.js'
import { SilentLog } from './support/silentLog.js'

const presenter = new HarmonicaPresenter([])

test('cup_whenTheHandsClose_tellsTheEngineHowFar', () => {
    const engine = new RecordingAudioEngine()
    const harmonica = new PlayHarmonica(engine, new SilentLog())

    harmonica.cupHands(cupDepth(0.6))

    assert.ok(Math.abs((engine.cups[engine.cups.length - 1] ?? 0) - 0.6) < 0.001)
})

test('cup_whenTheHandsHoldStill_tellsTheEngineOnce', () => {
    const engine = new RecordingAudioEngine()
    const harmonica = new PlayHarmonica(engine, new SilentLog())
    harmonica.cupHands(cupDepth(0.6))

    harmonica.cupHands(cupDepth(0.6))

    assert.equal(engine.cups.length, 1)
})

test('cup_whenTheHandsClose_showsHowFarInTheTopBar', () => {
    const harmonica = new PlayHarmonica(new RecordingAudioEngine(), new SilentLog())

    const state = presenter.present(harmonica.cupHands(cupDepth(0.6)), false)

    assert.equal(state.kind, 'ready')
    assert.ok(state.kind === 'ready' && Math.abs(state.playable.cup.closed - 0.6) < 0.001)
})
