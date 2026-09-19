import { test } from 'node:test'
import assert from 'node:assert/strict'
import { PlayHarmonica } from '../src/domain/useCases/playHarmonica.js'
import { pitchShaping } from '../src/domain/playing/pitchShaping.js'
import { vibratoDepth, vibratoOff } from '../src/domain/playing/vibratoDepth.js'
import type { PositionOnHarmonica } from '../src/domain/playing/positionOnHarmonica.js'
import { RecordingAudioEngine } from './support/recordingAudioEngine.js'
import { SilentLog } from './support/silentLog.js'

test('shapingZone_whenTheFingerGoesBelowTheMiddle_sendsTheNewBendAndVibrato', () => {
    const { harmonica, engine } = playing()

    harmonica.shapeTone(pitchShaping(-0.25), vibratoDepth(0.75))

    assert.equal(lastOf(engine.bends), 0.25)
    assert.equal(lastOf(engine.vibratos), 0.75)
})

test('shapingZone_whenTheFingerIsJustAboveTheMiddle_leavesTheReedSounding', () => {
    const { harmonica, engine } = blowingHoleThree()

    harmonica.shapeTone(pitchShaping(0.4), vibratoOff)

    assert.equal(engine.soundedTones.length, 1)
})

test('shapingZone_whenTheFingerPassesTheOverbendThreshold_soundsTheOverblowInstead', () => {
    const { harmonica, engine } = blowingHoleThree()

    harmonica.shapeTone(pitchShaping(0.6), vibratoOff)

    assert.ok(Math.abs(engine.hertzOfTheLastTone - 523.25) < 0.5, 'G4 overblown is C5')
    assert.equal(engine.soundedTones[1]?.[0]?.bendableSemitones, 0)
})

test('shapingZone_whenTheOverblowStarts_crossfadesAsANewReedRatherThanASlide', () => {
    const { harmonica, engine } = blowingHoleThree()

    harmonica.shapeTone(pitchShaping(0.6), vibratoOff)

    assert.deepEqual(engine.toneChanges, ['slide', 'newReed'])
})

test('shapingZone_whenTheFingerLeavesTheOverbend_soundsThePlainReedAgain', () => {
    const { harmonica, engine } = blowingHoleThree()
    harmonica.shapeTone(pitchShaping(0.6), vibratoOff)

    harmonica.shapeTone(pitchShaping(0.1), vibratoOff)

    assert.ok(Math.abs(engine.hertzOfTheLastTone - 392.0) < 0.5, 'hole 3 blows G4')
})

test('bend_whenAChordSounds_pullsEveryReedAsFarAsTheShallowestChamber', () => {
    const { harmonica, engine } = playing()

    harmonica.playAt([finger(0.25, -0.3), finger(0.35, -0.3)])

    assert.deepEqual(
        engine.soundedTones[0]?.map(tone => tone.bendableSemitones),
        [1, 1],
        'hole 3 draw bends three alone, hole 4 draw one, and one mouth pulls them together'
    )
})

test('shapingZone_whenTheFingerStaysStill_sendsNothingTwice', () => {
    const { harmonica, engine } = playing()
    harmonica.shapeTone(pitchShaping(-0.5), vibratoDepth(0.5))

    harmonica.shapeTone(pitchShaping(-0.5), vibratoDepth(0.5))

    assert.equal(engine.bends.length, 1)
})

test('harmonica_whenAFingerIsOnHoleThreeBelowTheLine_soundsTheDrawReed', () => {
    const { harmonica, engine } = playing()

    harmonica.playAt([finger(0.25, -0.3)])

    assert.equal(engine.soundedTones[0]?.length, 1)
    assert.equal(engine.soundedTones[0]?.[0]?.bendableSemitones, 3)
})

test('harmonica_whenAFingerCrossesToAnotherHoleAndBreath_soundsNeitherHalfwayHouse', () => {
    const { harmonica, engine } = playing()
    harmonica.playAt([finger(0.15, -0.3)])

    harmonica.playAt([finger(0.18, -0.03)])
    harmonica.playAt([finger(0.23, 0.03)])
    harmonica.playAt([finger(0.25, 0.2)])

    assert.deepEqual(
        engine.hertzOfEveryTone,
        [392, 392],
        'hole 2 drawn is G4, then hole 3 blown is G4, and nothing in between'
    )
    assert.equal(engine.soundedTones.length, 2, 'neither hole 2 blown nor hole 3 drawn ever sounded')
})

test('harmonica_whenTheBreathTurnsWhileAHoleSounds_makesEveryReedSpeakAgain', () => {
    const { harmonica, engine } = playing()
    harmonica.playAt([finger(0.25, 0.2)])

    harmonica.playAt([finger(0.25, -0.3)])

    assert.deepEqual(engine.toneChanges, ['slide', 'breathReversed'])
})

test('harmonica_whenTheTopmostFingerIsAboveTheLine_blowsEveryHole', () => {
    const { harmonica, engine } = playing()

    harmonica.playAt([finger(0.05, 0.2), finger(0.25, -0.4)])

    assert.deepEqual(engine.soundedTones[0]?.map(tone => tone.bendableSemitones), [0, 0])
})

test('harmonica_whenTheTopmostFingerHasSlidOffTheStrip_leavesTheBreathToTheNext', () => {
    const { harmonica, engine } = playing()

    harmonica.playAt([finger(1.4, 0.4), finger(0.25, -0.3)])

    assert.equal(engine.soundedTones[0]?.length, 1)
    assert.equal(engine.soundedTones[0]?.[0]?.bendableSemitones, 3)
})

function playing(): { harmonica: PlayHarmonica; engine: RecordingAudioEngine } {
    const engine = new RecordingAudioEngine()
    const harmonica = new PlayHarmonica(engine, new SilentLog())
    harmonica.changeMouthWidth(1)
    return { harmonica, engine }
}

function blowingHoleThree(): { harmonica: PlayHarmonica; engine: RecordingAudioEngine } {
    const playable = playing()
    playable.harmonica.playAt([finger(0.25, 0.2)])
    return playable
}

function finger(fromLeftEdge: number, aboveCentreLine: number): PositionOnHarmonica {
    return { fractionFromLeftEdge: fromLeftEdge, fractionAboveCentreLine: aboveCentreLine }
}

function lastOf(values: readonly number[]): number | undefined {
    return values[values.length - 1]
}
