import HarmonicaCore
import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

final class ReedSamplerUnitTests: XCTestCase {
    // MARK: - Tests

    func test_vibrato_whenAtFullDepth_makesThePitchWobble() throws {
        let sampler = sounding(hertz: 440, bendableSemitones: 0)
        sampler.changeVibrato(to: 1)

        let frequencies = (0..<20).map { _ in RenderedSound.frequency(of: sampler) }

        let spread = try XCTUnwrap(frequencies.max()) - XCTUnwrap(frequencies.min())
        XCTAssertGreaterThan(spread, 5, "440 Hz swung by 1.5 per cent covers 13 Hz, so it cannot be flat")
    }

    func test_vibrato_whenAtFullDepth_alsoPulsesTheLoudness() throws {
        let sampler = sounding(hertz: 440)
        sampler.changeVibrato(to: 1)

        let levels = (0..<20).map { _ in RenderedSound.loudness(of: sampler) }

        let swing = try XCTUnwrap(levels.max()) / XCTUnwrap(levels.min())
        XCTAssertGreaterThan(swing, 1.15, "a vibrato pulses the note, not only its pitch")
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

    func test_cup_whenTheHandsShut_takeTheTopOffTheSound() {
        let low = cupped(hertz: 600)
        let high = cupped(hertz: 2400)

        let kept = RenderedSound.loudness(of: low) / RenderedSound.loudness(of: high)

        XCTAssertGreaterThan(kept, 2, "shut hands pass 800 Hz and hold back what is above it")
    }

    func test_release_whenTheMouthComesOff_ringsOnAfterATonguedStopHasGone() {
        let released = sounding(hertz: 440)
        let tongued = sounding(hertz: 440)
        released.ringDown()
        tongued.damp()
        RenderedSound.render(1, from: released)
        RenderedSound.render(1, from: tongued)

        XCTAssertLessThan(RenderedSound.loudness(of: tongued), 0.001, "a tongued reed is gone inside 20 ms")
        XCTAssertGreaterThan(RenderedSound.loudness(of: released), 0.02, "a released reed rings about 30 cycles")
    }

    func test_vibrato_whenOff_holdsThePitchSteady() throws {
        let sampler = sounding(hertz: 440, bendableSemitones: 0)

        let frequencies = (0..<20).map { _ in RenderedSound.frequency(of: sampler) }

        let spread = try XCTUnwrap(frequencies.max()) - XCTUnwrap(frequencies.min())
        XCTAssertLessThan(spread, 2, "the estimator alone wanders half a hertz between buffers")
    }

    func test_bend_whenFullyPulledOnAThreeSemitoneReed_landsThreeSemitonesLower() {
        let sampler = sounding(hertz: 493.88, bendableSemitones: 3)

        sampler.changeBend(to: 1)

        XCTAssertEqual(RenderedSound.frequency(of: sampler), 415.30, accuracy: 4)
    }

    func test_note_whenTheNearestRecordingIsASemitoneAway_soundsThePitchThatWasAskedFor() {
        let sampler = sounding(hertz: 466.16)

        XCTAssertEqual(RenderedSound.frequency(of: sampler), 466.16, accuracy: 4, "A♭4 is recorded, A4 is not")
    }

    func test_note_whenTheRecordingRunsPastItsLoop_keepsSoundingTheSamePitch() {
        let sampler = sounding(hertz: 440)
        RenderedSound.render(30, from: sampler)

        XCTAssertEqual(RenderedSound.frequency(of: sampler), 440, accuracy: 4, "the loop holds 44 whole cycles")
    }

    func test_bend_whenTheReedCannotBend_leavesThePitchWhereItWas() {
        let sampler = sounding(hertz: 698.46, bendableSemitones: 0)

        sampler.changeBend(to: 1)

        XCTAssertEqual(RenderedSound.frequency(of: sampler), 698.46, accuracy: 4)
    }

    // MARK: - Helpers

    private func sounding(hertz: Double, bendableSemitones: Double = 0) -> ReedSampler {
        sounding([SoundingTone(hertz: hertz, bendableSemitones: bendableSemitones)])
    }

    private func cupped(hertz: Double) -> ReedSampler {
        let sampler = sounding(hertz: hertz)
        sampler.cupHands(to: 1)
        RenderedSound.settle(sampler)
        return sampler
    }

    private func sounding(_ tones: [SoundingTone]) -> ReedSampler {
        let sampler = ReedSampler(samples: SineSamples.bank(), log: RecordingLog())
        sampler.sound(tones, over: 0.02, everyReedSpeaksAgain: false)
        sampler.changeBreathGain(to: 1)
        RenderedSound.settle(sampler)
        return sampler
    }
}
