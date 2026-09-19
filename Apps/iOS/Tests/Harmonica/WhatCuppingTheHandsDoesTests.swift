import Foundation
import XCTest
@testable import MobileHarmonica
import HarmonicaCore
import HarmonicaCoreTestSupport

final class WhatCuppingTheHandsDoesTests: XCTestCase {
    private let engine = RecordingAudioEngine()
    private let presenter = HarmonicaPresenter(locale: Locale(identifier: "en_US_POSIX"), tunes: [])

    // MARK: - Tests

    func test_cup_whenTheHandsClose_tellsTheEngineHowFar() {
        let harmonica = harmonica()

        _ = harmonica.cupHands(to: CupDepth(clamping: 0.6))

        XCTAssertEqual(engine.cups.last?.fraction, 0.6)
    }

    func test_cup_whenTheHandsHoldStill_tellsTheEngineOnce() {
        let harmonica = harmonica()
        _ = harmonica.cupHands(to: CupDepth(clamping: 0.6))

        _ = harmonica.cupHands(to: CupDepth(clamping: 0.6))

        XCTAssertEqual(engine.cups.count, 1)
    }

    func test_cup_whenTheHandsClose_showsHowFarInTheTopBar() {
        let harmonica = harmonica()

        let state = presenter.present(harmonica.cupHands(to: CupDepth(clamping: 0.6)), playingAScore: false)

        guard case .ready(let playable) = state else { return XCTFail("the harmonica is ready") }

        XCTAssertEqual(playable.cup.closed, 0.6)
    }

    // MARK: - Helpers

    private func harmonica() -> PlayHarmonica {
        PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
    }
}
