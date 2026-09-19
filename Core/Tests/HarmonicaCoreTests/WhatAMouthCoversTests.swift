import XCTest
@testable import HarmonicaCore
import HarmonicaCoreTestSupport

final class WhatAMouthCoversTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_mouth_whenItIsFourHolesWide_coversFourHoles() {
        let harmonica = playing(.holesWide(.fourHoles))

        let sounding = harmonica.play(at: [finger(at: 0.25, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding.count, 4, "four is four rather than three and a half")
    }

    func test_mouth_whenItIsTwoHolesWideBetweenTwoHoles_coversBoth() {
        let harmonica = playing(.holesWide(.twoHoles))

        let sounding = harmonica.play(at: [finger(at: 0.29, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.three, .four])
    }

    func test_mouth_whenItIsOneHoleWide_takesTheHoleItIsOver() {
        let harmonica = playing(.holesWide(.oneHole))

        let sounding = harmonica.play(at: [finger(at: 0.29, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.three], "one hole is exact rather than nearly exact")
    }

    func test_mouth_whenItHangsOverTheEndOfTheComb_coversOnlyTheHolesThatAreThere() {
        let harmonica = playing(.holesWide(.fourHoles))

        let sounding = harmonica.play(at: [finger(at: 0.02, above: 0.2)]).soundingHoles

        XCTAssertEqual(sounding, [.one, .two])
    }

    func test_mouth_whenMeasuredByTheContact_spreadsFromItsEdges() {
        let harmonica = playing(.theContactItself)

        let sounding = harmonica.play(at: [
            PositionOnHarmonica(
                fractionFromLeftEdge: 0.25,
                fractionAboveCentreLine: 0.2,
                fractionCoveredEitherSide: 0.06
            )
        ]).soundingHoles

        XCTAssertEqual(sounding, [.two, .three, .four], "the contact reaches a hole either side")
    }

    func test_mouth_whenItsMeasureChangesWhileAHoleSounds_silencesIt() {
        let harmonica = playing(.holesWide(.oneHole))
        _ = harmonica.play(at: [finger(at: 0.25, above: 0.2)])

        let sounding = harmonica.changeMouth(to: .holesWide(.threeHoles)).soundingHoles

        XCTAssertEqual(sounding, [])
        XCTAssertEqual(engine.silencings, 1)
    }

    // MARK: - Helpers

    private func playing(_ mouth: MouthMeasure) -> PlayHarmonica {
        let harmonica = PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
        _ = harmonica.changeMouth(to: mouth)
        return harmonica
    }

    private func finger(at fromLeftEdge: Double, above centreLine: Double) -> PositionOnHarmonica {
        PositionOnHarmonica(fractionFromLeftEdge: fromLeftEdge, fractionAboveCentreLine: centreLine)
    }
}
