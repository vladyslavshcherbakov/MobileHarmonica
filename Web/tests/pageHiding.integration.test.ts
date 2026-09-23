import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { HarmonicaViewModel } from '../src/features/harmonica/harmonicaViewModel.js'
import { isCollected } from './support/collectedGarbage.js'
import { TestEnvironment, withoutTheBuiltCore } from './support/testEnvironment.js'
import { waitUntil } from './support/waitUntil.js'

const tuneStoppedLine = 'the tune was stopped'
const longestFirstNoteSeconds = 10

test('harmonicaScreen_whenHiddenWhileATunePlays_stopsTheTune', { skip: withoutTheBuiltCore }, async () => {
    const environment = new TestEnvironment()
    const screen = await environment.harmonicaScreen()
    screen.playTune(0)
    await waitUntil(() => environment.audio.soundedTones.length > 0)

    screen.hideThePage()

    const didTheTuneStop = await waitUntil(
        () => environment.log.lines.includes(tuneStoppedLine),
        longestFirstNoteSeconds
    )
    assert.ok(didTheTuneStop, 'the tune never said it stopped')
    assert.equal(environment.log.lines.includes('the tune ended'), false)
    assert.equal(screen.state.kind === 'ready' && screen.state.playable.demo.isPlaying, false)
})

test('harmonicaScreen_whenHiddenWhileATunePlays_isReleased', { skip: withoutTheBuiltCore }, async () => {
    const environment = new TestEnvironment()

    const viewModel = await hiddenWhileATunePlays(environment)

    assert.ok(await isCollected(viewModel), 'something still holds the screen after its tune stopped')
})

async function hiddenWhileATunePlays(environment: TestEnvironment): Promise<WeakRef<HarmonicaViewModel>> {
    const screen = await environment.harmonicaScreen()
    screen.playTune(0)
    await waitUntil(() => environment.audio.soundedTones.length > 0)
    screen.hideThePage()
    await waitUntil(() => environment.log.lines.includes(tuneStoppedLine), longestFirstNoteSeconds)
    return new WeakRef(screen.viewModel)
}
