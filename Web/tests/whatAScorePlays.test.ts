import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { Harmonica } from '../src/domain/instrument/harmonica.js'
import type { Score, ScoreEvent } from '../src/domain/scores/score.js'
import { blow, draw, overblow, rest } from '../src/domain/scores/scoreWriting.js'
import { PlayHarmonica } from '../src/domain/useCases/playHarmonica.js'
import { PlayScore } from '../src/domain/useCases/playScore.js'
import { RecordingAudioEngine } from './support/recordingAudioEngine.js'
import { SilentLog } from './support/silentLog.js'

test('score_whenItNamesAHole_soundsThatHolesReed', async () => {
    const engine = await play([blow(4, 1)])

    assert.ok(Math.abs(engine.hertzOfTheFirstTone - 523.25) < 0.5, 'hole 4 blows C5')
})

test('score_whenANoteIsBentBySemitones_bendsThatFarIntoTheReedsRange', async () => {
    const engine = await play([draw(3, 1, { bentBy: 1 })])

    assert.ok(
        engine.bends.some(bend => Math.abs(bend - 0.33) < 0.005),
        'a semitone of the three the hole 3 draw reed bends'
    )
})

test('score_whenANoteIsOverbent_soundsTheOverblow', async () => {
    const engine = await play([overblow(3, 1)])

    assert.ok(Math.abs(engine.hertzOfTheFirstTone - 523.25) < 0.5, 'hole 3 overblown is C5')
})

test('score_whenARestComes_soundsNothingForItsLength', async () => {
    const engine = await play([draw(4, 1), rest(1), draw(4, 1)])

    assert.equal(engine.soundedTones.length, 2, 'the rest between the two notes adds nothing')
    assert.ok(engine.silencings > 1, 'each note ends silent')
})

test('score_whenItEnds_leavesNothingSounding', async () => {
    const engine = await play([draw(4, 1)])

    assert.equal(engine.soundedTones[engine.soundedTones.length - 1]?.length, 1)
    assert.ok(engine.silencings > 0)
})

test('score_whenAnEventNamesSeveralHoles_soundsThemAsAChord', async () => {
    const engine = await play([draw([1, 2, 3], 1)])

    assert.equal(engine.soundedTones[0]?.length, 3, 'holes 1 to 3 drawn are D4 G4 B4')
})

test('score_whenThePlayingStyleTakesOneFinger_stillSoundsEveryHoleTheScoreNames', async () => {
    const engine = new RecordingAudioEngine()
    const harmonica = new PlayHarmonica(engine, new SilentLog())
    harmonica.changeStyle('oneFingerSeveralNotes')

    await play([draw([1, 2, 3], 1)], { harmonica, engine })

    assert.equal(engine.soundedTones[0]?.length, 3, 'a score names holes, so nothing reinterprets them')
})

test('score_whenItIsPlayedInSecondPosition_callsForTheHarmonicaAFifthBelow', async () => {
    const blues = tune([], { key: 'G', position: 'second' })

    const played = await playedStates(blues)

    assert.equal(played[0]?.key, 'C', 'a blues in G is played on a harmonica in C')
})

test('score_whenItIsPlayedInFirstPosition_callsForTheHarmonicaItIsWrittenIn', async () => {
    const played = await playedStates(tune([], { key: 'D', position: 'first' }))

    assert.equal(played[0]?.key, 'D')
})

test('score_whenANoteSlidesUpFromAnotherHole_soundsTheHolesOnTheWay', async () => {
    const engine = await play([draw(4, 1, { slideFrom: 1 })])

    assert.equal(engine.soundedTones.length, 4, 'holes 1, 2 and 3 pass before hole 4 arrives')
    assert.ok(Math.abs(engine.hertzOfTheLastTone - 587.33) < 0.5, 'hole 4 draws D5')
})

test('score_whenANoteSlidesDownFromAnotherHole_passesTheHolesInReverse', async () => {
    const engine = await play([draw(1, 1, { slideFrom: 3 })])

    assert.equal(engine.soundedTones.length, 3)
    assert.ok(Math.abs(engine.hertzOfTheFirstTone - 493.88) < 0.5, 'hole 3 draws B4 first')
})

test('score_whenTheSlideStartsWhereTheNoteIs_soundsOnlyTheNote', async () => {
    const engine = await play([draw(4, 1, { slideFrom: 4 })])

    assert.equal(engine.soundedTones.length, 1)
})

test('score_whenANoteIsShaken_rocksBetweenTheTwoHoles', async () => {
    const engine = await play([draw(4, 1, { shakenWith: 5 })], { beatsPerMinute: 240 })

    const hertz = engine.hertzOfEveryTone
    assert.ok(hertz.length > 2, 'a shaken note re-sounds on every swing')
    assert.ok(Math.abs((hertz[0] ?? 0) - 587.33) < 1, 'hole 4 draws D5')
    assert.ok(Math.abs((hertz[1] ?? 0) - 698.46) < 1, 'hole 5 draws F5')
})

test('score_whenABendIsReleased_walksTheBendBackToNothing', async () => {
    const engine = await play(
        [draw(3, 1, { bentBy: 2, releasingTo: 0 })],
        { beatsPerMinute: 240 }
    )

    const bends = engine.bends
    assert.ok(Math.abs((bends[0] ?? 0) - 0.67) < 0.02, 'two of the three semitones hole 3 draw bends')
    assert.ok(Math.abs(bends[bends.length - 1] ?? 1) < 0.02)
})

test('score_whenANoteIsPlain_soundsItOnce', async () => {
    const engine = await play([draw(4, 1)])

    assert.equal(engine.soundedTones.length, 1, 'no expression means no stepping')
})

interface Playable {
    harmonica: PlayHarmonica
    engine: RecordingAudioEngine
}

function tune(
    events: readonly ScoreEvent[],
    written: { key?: Score['key']; position?: Score['position']; beatsPerMinute?: number } = {}
): Score {
    return {
        name: 'test',
        key: written.key ?? 'C',
        position: written.position ?? 'first',
        beatsPerMinute: written.beatsPerMinute ?? 6000,
        events
    }
}

async function play(
    events: readonly ScoreEvent[],
    on: Partial<Playable> & { beatsPerMinute?: number } = {}
): Promise<RecordingAudioEngine> {
    const engine = on.engine ?? new RecordingAudioEngine()
    const harmonica = on.harmonica ?? new PlayHarmonica(engine, new SilentLog())
    const written = on.beatsPerMinute === undefined ? {} : { beatsPerMinute: on.beatsPerMinute }
    await playedStates(tune(events, written), { harmonica, engine })
    return engine
}

async function playedStates(score: Score, on?: Playable): Promise<Harmonica[]> {
    const engine = on?.engine ?? new RecordingAudioEngine()
    const harmonica = on?.harmonica ?? new PlayHarmonica(engine, new SilentLog())
    const player = new PlayScore(harmonica, new SilentLog())

    const played: Harmonica[] = []
    await player.play(score, state => played.push(state)).finished
    return played
}
