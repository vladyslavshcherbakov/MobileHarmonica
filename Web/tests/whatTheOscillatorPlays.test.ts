import { test } from 'node:test'
import assert from 'node:assert/strict'
import { Oscillator, sineBank } from '../src/audio/harmonicaWorklet.js'
import type { SoundingTone } from '../src/audio/workletMessage.js'
import { frequencyOf, loudnessOf, render, sampleRate, settle } from './support/renderedSound.js'

test('vibrato_whenAtFullDepth_makesThePitchWobble', () => {
    const oscillator = sounding(440, 0)
    oscillator.changeVibrato(1)

    const frequencies = Array.from({ length: 20 }, () => frequencyOf(oscillator))

    const spread = Math.max(...frequencies) - Math.min(...frequencies)
    assert.ok(spread > 5, '440 Hz swung by 1.5 per cent covers 13 Hz, so it cannot be flat')
})

test('vibrato_whenAtFullDepth_alsoPulsesTheLoudness', () => {
    const oscillator = sounding(440)
    oscillator.changeVibrato(1)

    const levels = Array.from({ length: 20 }, () => loudnessOf(oscillator))

    assert.ok(Math.max(...levels) / Math.min(...levels) > 1.15, 'a vibrato pulses the note, not only its pitch')
})

test('chord_whenThreeReedsSoundTogether_isLouderThanOneReedAlone', () => {
    const one = sounding(440)
    const three = soundingTones([
        { hertz: 440, bendableSemitones: 0 },
        { hertz: 550, bendableSemitones: 0 },
        { hertz: 660, bendableSemitones: 0 }
    ])

    const louder = loudnessOf(three) / loudnessOf(one)

    assert.ok(louder > 1.5, 'three reeds move about the square root of three times the air')
})

test('cup_whenTheHandsShut_takeTheTopOffTheSound', () => {
    const low = cupped(600)
    const high = cupped(2400)

    const kept = loudnessOf(low) / loudnessOf(high)

    assert.ok(kept > 2, 'shut hands pass 800 Hz and hold back what is above it')
})

test('release_whenTheMouthComesOff_ringsOnAfterATonguedStopHasGone', () => {
    const released = sounding(440)
    const tongued = sounding(440)
    released.ringDown()
    tongued.damp(0.02)
    render(1, released)
    render(1, tongued)

    assert.ok(loudnessOf(tongued) < 0.001, 'a tongued reed is gone inside 20 ms')
    assert.ok(loudnessOf(released) > 0.02, 'a released reed rings about 30 cycles')
})

test('vibrato_whenOff_holdsThePitchSteady', () => {
    const oscillator = sounding(440, 0)

    const frequencies = Array.from({ length: 20 }, () => frequencyOf(oscillator))

    const spread = Math.max(...frequencies) - Math.min(...frequencies)
    assert.ok(spread < 2, 'the estimator alone wanders half a hertz between buffers')
})

test('bend_whenFullyPulledOnAThreeSemitoneReed_landsThreeSemitonesLower', () => {
    const oscillator = sounding(493.88, 3)

    oscillator.changeBend(1)

    assert.ok(Math.abs(frequencyOf(oscillator) - 415.3) < 4)
})

test('note_whenTheRecordingIsASemitoneAway_soundsThePitchThatWasAskedFor', () => {
    const oscillator = sounding(466.16)

    assert.ok(Math.abs(frequencyOf(oscillator) - 466.16) < 4, 'the bank holds 440 alone, so 466.16 is stretched to it')
})

test('note_whenTheRecordingRunsPastItsLoop_keepsSoundingTheSamePitch', () => {
    const oscillator = sounding(440)
    render(30, oscillator)

    assert.ok(Math.abs(frequencyOf(oscillator) - 440) < 4, 'the loop holds 44 whole cycles')
})

test('bend_whenTheReedCannotBend_leavesThePitchWhereItWas', () => {
    const oscillator = sounding(698.46, 0)

    oscillator.changeBend(1)

    assert.ok(Math.abs(frequencyOf(oscillator) - 698.46) < 4)
})

function sounding(hertz: number, bendableSemitones = 0): Oscillator {
    return soundingTones([{ hertz, bendableSemitones }])
}

function cupped(hertz: number): Oscillator {
    const oscillator = sounding(hertz)
    oscillator.cupHands(1)
    settle(oscillator)
    return oscillator
}

function soundingTones(tones: readonly SoundingTone[]): Oscillator {
    const oscillator = new Oscillator(sineBank(sampleRate), sampleRate)
    oscillator.sound(tones, 0.02, false)
    oscillator.changeBreathGain(1)
    settle(oscillator)
    return oscillator
}
