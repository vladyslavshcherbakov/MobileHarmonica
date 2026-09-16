import XCTest
@testable import MobileHarmonica

final class WhatTheMouthCoversTests: XCTestCase {
    private let engine = RecordingAudioEngine()

    // MARK: - Tests

    func test_mouth_whenTheContactIsNarrowerThanAHole_soundsOneHole() {
        let harmonica = mouth()

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.02, above: 0.2)])

        XCTAssertEqual(sounding, [.three])
    }

    func test_mouth_whenTheContactCrossesAHoleBoundary_soundsBothHoles() {
        let harmonica = mouth()

        let sounding = harmonica.play(at: [contact(at: 0.29, covering: 0.02, above: 0.2)])

        XCTAssertEqual(sounding, [.three, .four])
    }

    func test_mouth_whenTheContactSpansThreeHoles_soundsAllThree() {
        let harmonica = mouth()

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.06, above: 0.2)])

        XCTAssertEqual(sounding, [.two, .three, .four])
    }

    func test_mouth_whenTheCentreIsBelowTheLine_drawsEveryCoveredHole() {
        let harmonica = mouth()

        _ = harmonica.play(at: [contact(at: 0.29, covering: 0.02, above: -0.3)])

        XCTAssertEqual(engine.soundedTones.last?.map(\.bendableSemitones), [3, 1])
    }

    func test_mouth_whenASecondFingerIsOnTheStrip_soundsOnlyTheTopmost() {
        let harmonica = mouth()

        let sounding = harmonica.play(at: [
            contact(at: 0.05, covering: 0.02, above: 0.2),
            contact(at: 0.45, covering: 0.02, above: -0.3)
        ])

        XCTAssertEqual(sounding, [.one])
    }

    func test_fingers_whenTheContactIsWide_stillSoundsOneHolePerFinger() {
        let harmonica = harmonica()

        let sounding = harmonica.play(at: [contact(at: 0.25, covering: 0.06, above: 0.2)])

        XCTAssertEqual(sounding, [.three])
    }

    func test_playingStyle_whenSwitchedWhileAHoleSounds_silencesIt() {
        let harmonica = harmonica()
        _ = harmonica.play(at: [contact(at: 0.25, covering: 0.02, above: 0.2)])

        let sounding = harmonica.changeStyle(to: .mouth)

        XCTAssertEqual(sounding, [])
        XCTAssertEqual(engine.silencings, 1)
    }

    // MARK: - Helpers

    private func harmonica() -> PlayHarmonica {
        PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
    }

    private func mouth() -> PlayHarmonica {
        let harmonica = harmonica()
        _ = harmonica.changeStyle(to: .mouth)
        return harmonica
    }

    private func contact(at fromLeftEdge: Double, covering eitherSide: Double, above centreLine: Double) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: fromLeftEdge,
            fractionAboveCentreLine: centreLine,
            fractionCoveredEitherSide: eitherSide
        )
    }
}
