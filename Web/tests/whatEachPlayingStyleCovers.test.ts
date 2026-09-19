import { test } from 'node:test'
import assert from 'node:assert/strict'
import { PlayHarmonica } from '../src/domain/useCases/playHarmonica.js'
import type { MouthWidth } from '../src/domain/playing/mouthWidth.js'
import type { PlayingStyle } from '../src/domain/playing/playingStyle.js'
import type { PositionOnHarmonica } from '../src/domain/playing/positionOnHarmonica.js'
import { RecordingAudioEngine } from './support/recordingAudioEngine.js'
import { SilentLog } from './support/silentLog.js'

test('oneNotePerFinger_whenTheMouthIsWide_soundsOneHolePerFinger', () => {
    const { harmonica } = playing('severalFingersOneNote', 3)

    const sounding = harmonica.playAt([finger(0.25, 0.2)]).soundingHoles

    assert.deepEqual(sounding, [3])
})

test('oneNotePerFinger_whenTwoFingersAreDown_soundsAHolePerFinger', () => {
    const { harmonica } = playing('severalFingersOneNote', 3)

    const sounding = harmonica.playAt([finger(0.05, 0.2), finger(0.45, 0.2)]).soundingHoles

    assert.deepEqual(sounding, [1, 5])
})

test('severalNotesPerFinger_whenTheMouthIsOneHoleWide_soundsOneHole', () => {
    const { harmonica } = playing('severalFingersSeveralNotes', 1)

    const sounding = harmonica.playAt([finger(0.25, 0.2)]).soundingHoles

    assert.deepEqual(sounding, [3])
})

test('severalNotesPerFinger_whenTheMouthSpansAHoleBoundary_soundsBothHoles', () => {
    const { harmonica } = playing('severalFingersSeveralNotes', 2)

    const sounding = harmonica.playAt([finger(0.29, 0.2)]).soundingHoles

    assert.deepEqual(sounding, [3, 4])
})

test('severalNotesPerFinger_whenASecondFingerIsDown_soundsWhatBothFingersCover', () => {
    const { harmonica } = playing('severalFingersSeveralNotes', 2)

    const sounding = harmonica.playAt([finger(0.05, 0.2), finger(0.45, -0.3)]).soundingHoles

    assert.deepEqual(sounding, [1, 4, 5], 'one finger brings a hole, the other brings two')
})

test('oneFinger_whenTheMouthSpansThreeHoles_soundsAllThree', () => {
    const { harmonica } = playing('oneFingerSeveralNotes', 3)

    const sounding = harmonica.playAt([finger(0.25, 0.2)]).soundingHoles

    assert.deepEqual(sounding, [2, 3, 4])
})

test('oneFinger_whenASecondFingerIsOnTheStrip_soundsOnlyTheTopmost', () => {
    const { harmonica } = playing('oneFingerSeveralNotes', 1)

    const sounding = harmonica.playAt([finger(0.05, 0.2), finger(0.45, -0.3)]).soundingHoles

    assert.deepEqual(sounding, [1])
})

test('oneFinger_whenTheCentreIsBelowTheLine_drawsEveryCoveredHole', () => {
    const { harmonica, engine } = playing('oneFingerSeveralNotes', 2)

    harmonica.playAt([finger(0.29, -0.3)])

    assert.deepEqual(
        engine.hertzOfEveryTone.length,
        1,
        'the two covered holes sound as one chord'
    )
    assert.deepEqual(
        engine.soundedTones[0]?.map(tone => Math.round(tone.hertz)),
        [494, 587],
        'holes 3 and 4 draw B4 and D5, where blowing them would be G4 and C5'
    )
})

test('mouth_whenItIsFourHolesWide_coversFourHoles', () => {
    const { harmonica } = playing('severalFingersSeveralNotes', 4)

    const sounding = harmonica.playAt([finger(0.25, 0.2)]).soundingHoles

    assert.equal(sounding.length, 4, 'four is four rather than three and a half')
})

test('mouth_whenItHangsOverTheEndOfTheComb_coversOnlyTheHolesThatAreThere', () => {
    const { harmonica } = playing('severalFingersSeveralNotes', 4)

    const sounding = harmonica.playAt([finger(0.02, 0.2)]).soundingHoles

    assert.deepEqual(sounding, [1, 2])
})

test('playingStyle_whenSwitchedWhileAHoleSounds_silencesIt', () => {
    const { harmonica, engine } = playing('severalFingersSeveralNotes', 1)
    harmonica.playAt([finger(0.25, 0.2)])

    const sounding = harmonica.changeStyle('severalFingersOneNote').soundingHoles

    assert.deepEqual(sounding, [])
    assert.equal(engine.silencings, 1)
})

test('mouthWidth_whenItChangesWhileAHoleSounds_silencesIt', () => {
    const { harmonica, engine } = playing('severalFingersSeveralNotes', 1)
    harmonica.playAt([finger(0.25, 0.2)])

    const sounding = harmonica.changeMouthWidth(3).soundingHoles

    assert.deepEqual(sounding, [])
    assert.equal(engine.silencings, 1)
})

function playing(style: PlayingStyle, width: MouthWidth): {
    harmonica: PlayHarmonica
    engine: RecordingAudioEngine
} {
    const engine = new RecordingAudioEngine()
    const harmonica = new PlayHarmonica(engine, new SilentLog())
    harmonica.changeStyle(style)
    harmonica.changeMouthWidth(width)
    return { harmonica, engine }
}

function finger(fromLeftEdge: number, aboveCentreLine: number): PositionOnHarmonica {
    return { fractionFromLeftEdge: fromLeftEdge, fractionAboveCentreLine: aboveCentreLine }
}
