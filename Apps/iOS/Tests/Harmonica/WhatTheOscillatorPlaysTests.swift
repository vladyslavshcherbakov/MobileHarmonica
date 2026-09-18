import XCTest
@testable import MobileHarmonica

final class WhatTheOscillatorPlaysTests: XCTestCase {
    // MARK: - Tests

    func test_vibrato_whenAtFullDepth_makesThePitchWobble() {
        let oscillator = sounding(hertz: 440, bendableSemitones: 0)
        oscillator.changeVibrato(to: 1)

        let frequencies = (0..<20).map { _ in RenderedSound.frequency(of: oscillator) }

        let spread = frequencies.max()! - frequencies.min()!
        XCTAssertGreaterThan(spread, 5, "440 Hz swung by 1.5 per cent covers 13 Hz, so it cannot be flat")
    }

    func test_vibrato_whenAtFullDepth_alsoPulsesTheLoudness() {
        let oscillator = sounding(hertz: 440)
        oscillator.changeVibrato(to: 1)

        let levels = (0..<20).map { _ in RenderedSound.loudness(of: oscillator) }

        XCTAssertGreaterThan(levels.max()! / levels.min()!, 1.15, "a vibrato pulses the note, not only its pitch")
    }

    func test_chord_whenThreeReedsSoundTogether_isLouderThanOneReedAlone() {
        let one = sounding(hertz: 440)
        let three = sounding([
            SoundingTone(hertz: 440, bendableSemitones: 0),
            SoundingTone(hertz: 550, bendableSemitones: 0),
            SoundingTone(hertz: 660, bendableSemitones: 0)
        ])

        let louder = RenderedSound.loudness(of: three) / RenderedSound.loudness(of: one)

        XCTAssertGreaterThan(louder, 1.5, "three reeds move about the square root of three times the air")
    }

    func test_cup_whenTheHandsShut_keepTheBandTheyRingAtAndLetGoOfTheRest() {
        let atTheRingingBand = cupped(hertz: 600)
        let twoOctavesAbove = cupped(hertz: 2400)

        let kept = RenderedSound.loudness(of: atTheRingingBand) / RenderedSound.loudness(of: twoOctavesAbove)

        XCTAssertGreaterThan(kept, 5, "shut hands ring near 600 Hz, which is what makes a wah a vowel")
    }

    func test_vibrato_whenOff_holdsThePitchSteady() {
        let oscillator = sounding(hertz: 440, bendableSemitones: 0)

        let frequencies = (0..<20).map { _ in RenderedSound.frequency(of: oscillator) }

        let spread = frequencies.max()! - frequencies.min()!
        XCTAssertLessThan(spread, 2, "the estimator alone wanders half a hertz between buffers")
    }

    func test_bend_whenFullyPulledOnAThreeSemitoneReed_landsThreeSemitonesLower() {
        let oscillator = sounding(hertz: 493.88, bendableSemitones: 3)

        oscillator.changeBend(to: 1)

        XCTAssertEqual(RenderedSound.frequency(of: oscillator), 415.30, accuracy: 4)
    }

    func test_note_whenTheNearestRecordingIsASemitoneAway_soundsThePitchThatWasAskedFor() {
        let oscillator = sounding(hertz: 466.16)

        XCTAssertEqual(RenderedSound.frequency(of: oscillator), 466.16, accuracy: 4, "A♭4 is recorded, A4 is not")
    }

    func test_note_whenTheRecordingRunsPastItsLoop_keepsSoundingTheSamePitch() {
        let oscillator = sounding(hertz: 440)
        RenderedSound.render(30, from: oscillator)

        XCTAssertEqual(RenderedSound.frequency(of: oscillator), 440, accuracy: 4, "the loop holds 44 whole cycles")
    }

    func test_bend_whenTheReedCannotBend_leavesThePitchWhereItWas() {
        let oscillator = sounding(hertz: 698.46, bendableSemitones: 0)

        oscillator.changeBend(to: 1)

        XCTAssertEqual(RenderedSound.frequency(of: oscillator), 698.46, accuracy: 4)
    }

    // MARK: - Helpers

    private func sounding(hertz: Double, bendableSemitones: Double = 0) -> Oscillator {
        sounding([SoundingTone(hertz: hertz, bendableSemitones: bendableSemitones)])
    }

    private func cupped(hertz: Double) -> Oscillator {
        let oscillator = sounding(hertz: hertz)
        oscillator.cupHands(to: 1)
        RenderedSound.settle(oscillator)
        return oscillator
    }

    private func sounding(_ tones: [SoundingTone]) -> Oscillator {
        let oscillator = Oscillator(samples: SineSamples.bank())
        oscillator.sound(tones, over: 0.02, everyReedSpeaksAgain: false)
        oscillator.changeBreathGain(to: 1)
        RenderedSound.settle(oscillator)
        return oscillator
    }
}
