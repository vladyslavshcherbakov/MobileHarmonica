import HarmonicaCoreTestSupport
import XCTest
@testable import HarmonicaCore

@MainActor
final class ToneShapingIntegrationTests: XCTestCase {
    private let environment = InstrumentEnvironment()

    // MARK: - Tests

    func test_shapingPad_whenTheFingerGoesAboveTheMiddle_sendsTheNewBendAndVibrato() {
        let harmonica = drawingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.25), vibrato: VibratoDepth(clamping: 0.75))

        XCTAssertEqual(environment.engine.bends.last?.fraction, 0.25)
        XCTAssertEqual(environment.engine.vibratos.last?.fraction, 0.75)
    }

    func test_shapingPad_whenTheFingerIsBelowTheMiddle_leavesThePitchAloneAndSendsTheVibrato() {
        let harmonica = drawingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: -0.8), vibrato: VibratoDepth(clamping: 0.75))

        XCTAssertEqual(environment.engine.bends.last?.fraction, 0)
        XCTAssertEqual(environment.engine.vibratos.last?.fraction, 0.75)
    }

    func test_shapingPad_whenABendingReedPassesTheOverbendThreshold_keepsBendingTheSameReed() {
        let harmonica = drawingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.6), vibrato: .off)

        XCTAssertEqual(environment.engine.bends.last?.fraction, 0.6)
        XCTAssertEqual(environment.engine.toneChanges, [.slide], "hole 3 draw bends and has no overbend to pop to")
    }

    func test_shapingPad_whenTheFingerIsJustAboveTheMiddle_leavesTheReedSounding() {
        let harmonica = blowingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.4), vibrato: .off)

        XCTAssertEqual(environment.engine.soundedTones.count, 1)
    }

    func test_shapingPad_whenTheFingerPassesTheOverbendThreshold_soundsTheOverblowInstead() {
        let harmonica = blowingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.6), vibrato: .off)

        XCTAssertEqual(environment.engine.hertzOfTheLastTone, 523.25, accuracy: 0.5, "G4 overblown is C5")
        XCTAssertEqual(environment.engine.soundedTones.last?.first?.bendableSemitones, 0)
    }

    func test_shapingPad_whenTheOverblowStarts_crossfadesAsANewReedRatherThanASlide() {
        let harmonica = blowingHoleThree()

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.6), vibrato: .off)

        XCTAssertEqual(environment.engine.toneChanges, [.slide, .newReed])
    }

    func test_shapingPad_whenTheFingerLeavesTheOverbend_soundsThePlainReedAgain() {
        let harmonica = blowingHoleThree()
        _ = harmonica.shapeTone(PitchShaping(clamping: 0.6), vibrato: .off)

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.1), vibrato: .off)

        XCTAssertEqual(environment.engine.hertzOfTheLastTone, 392.00, accuracy: 0.5, "hole 3 blows G4")
    }

    func test_bend_whenAChordSounds_pullsEveryReedAsFarAsTheShallowestChamber() {
        let harmonica = harmonica()

        _ = harmonica.play(at: [
            PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.3),
            PositionOnHarmonica(fractionFromLeftEdge: 0.35, fractionAboveCentreLine: -0.3)
        ])

        XCTAssertEqual(
            environment.engine.soundedTones.last?.map(\.bendableSemitones),
            [1, 1],
            "hole 3 draw bends three alone, hole 4 draw one, and one mouth pulls them together"
        )
    }

    func test_shapingPad_whenTheFingerStaysStill_sendsNothingTwice() {
        let harmonica = drawingHoleThree()
        _ = harmonica.shapeTone(PitchShaping(clamping: 0.5), vibrato: VibratoDepth(clamping: 0.5))

        _ = harmonica.shapeTone(PitchShaping(clamping: 0.5), vibrato: VibratoDepth(clamping: 0.5))

        XCTAssertEqual(environment.engine.bends.count, 1)
    }

    func test_harmonica_whenAFingerIsOnHoleThreeBelowTheLine_soundsTheDrawReed() {
        let harmonica = harmonica()

        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.3)])

        XCTAssertEqual(environment.engine.soundedTones.last?.count, 1)
        XCTAssertEqual(environment.engine.soundedTones.last?.first?.bendableSemitones, 3)
    }

    func test_harmonica_whenAFingerCrossesToAnotherHoleAndBreath_soundsNeitherHalfwayHouse() {
        let harmonica = harmonica()
        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.15, fractionAboveCentreLine: -0.3)])

        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.18, fractionAboveCentreLine: -0.03)])
        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.23, fractionAboveCentreLine: 0.03)])
        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: 0.2)])

        let hertz = environment.engine.soundedTones.compactMap { $0.first?.pitch.converted(to: .hertz).value.rounded() }
        XCTAssertEqual(hertz, [392, 392], "hole 2 drawn is G4, then hole 3 blown is G4, and nothing in between")
        XCTAssertEqual(environment.engine.soundedTones.count, 2, "neither hole 2 blown nor hole 3 drawn ever sounded")
    }

    func test_harmonica_whenTheBreathTurnsWhileAHoleSounds_makesEveryReedSpeakAgain() {
        let harmonica = harmonica()
        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: 0.2)])

        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.3)])

        XCTAssertEqual(environment.engine.toneChanges, [.slide, .breathReversed])
    }

    func test_harmonica_whenTheTopmostFingerIsAboveTheLine_blowsEveryHole() {
        let harmonica = harmonica()

        _ = harmonica.play(at: [
            PositionOnHarmonica(fractionFromLeftEdge: 0.05, fractionAboveCentreLine: 0.2),
            PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.4)
        ])

        XCTAssertEqual(environment.engine.soundedTones.last?.map(\.bendableSemitones), [0, 0])
    }

    func test_harmonica_whenTheTopmostFingerHasSlidOffTheStrip_leavesTheBreathToTheNext() {
        let harmonica = harmonica()

        _ = harmonica.play(at: [
            PositionOnHarmonica(fractionFromLeftEdge: 1.4, fractionAboveCentreLine: 0.4),
            PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.3)
        ])

        XCTAssertEqual(environment.engine.soundedTones.last?.count, 1)
        XCTAssertEqual(environment.engine.soundedTones.last?.first?.bendableSemitones, 3)
    }

    // MARK: - Helpers

    private func harmonica() -> PlayHarmonicaUseCase {
        environment.playHarmonica
    }

    private func drawingHoleThree() -> PlayHarmonicaUseCase {
        let harmonica = harmonica()
        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: -0.3)])
        return harmonica
    }

    private func blowingHoleThree() -> PlayHarmonicaUseCase {
        let harmonica = harmonica()
        _ = harmonica.play(at: [PositionOnHarmonica(fractionFromLeftEdge: 0.25, fractionAboveCentreLine: 0.2)])
        return harmonica
    }
}
