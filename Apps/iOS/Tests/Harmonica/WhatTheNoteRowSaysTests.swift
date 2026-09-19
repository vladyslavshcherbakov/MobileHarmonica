import Foundation
import HarmonicaCore
import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

final class WhatTheNoteRowSaysTests: XCTestCase {
    private let engine = RecordingAudioEngine()
    private let presenter = HarmonicaPresenter(locale: Locale(identifier: "en_US_POSIX"), tunes: [])

    // MARK: - Tests

    func test_noteRow_whenNoHoleSounds_namesNothing() {
        let harmonica = harmonica()

        let state = presenter.present(harmonica.play(at: []), playingAScore: false)

        XCTAssertEqual(hole(4, of: state)?.note, "")
        XCTAssertEqual(hole(4, of: state)?.effect, "")
    }

    func test_noteRow_whenTheFingerIsAboveTheLine_namesTheBlowReed() {
        let harmonica = harmonica()

        let state = presenter.present(harmonica.play(at: [finger(at: 0.35, above: 0.2)]), playingAScore: false)

        XCTAssertEqual(hole(4, of: state)?.note, "C5")
    }

    func test_noteRow_whenTheFingerIsBelowTheLine_namesTheDrawReed() {
        let harmonica = harmonica()

        let state = presenter.present(harmonica.play(at: [finger(at: 0.35, above: -0.3)]), playingAScore: false)

        XCTAssertEqual(hole(4, of: state)?.note, "D5")
    }

    func test_noteRow_whenTheDrawReedIsBentToItsLimit_namesTheBentNoteAndTheReedBehindIt() {
        let harmonica = harmonica()
        _ = harmonica.play(at: [finger(at: 0.35, above: -0.3)])

        let state = presenter.present(harmonica.shapeTone(PitchShaping(clamping: -1), vibrato: .off), playingAScore: false)

        XCTAssertEqual(hole(4, of: state)?.note, "D♭5")
        XCTAssertEqual(hole(4, of: state)?.effect, "(D5 bend)")
    }

    func test_noteRow_whenTheBlowReedIsOverbent_namesTheOverblow() {
        let harmonica = harmonica()
        _ = harmonica.play(at: [finger(at: 0.25, above: 0.2)])

        let state = presenter.present(harmonica.shapeTone(PitchShaping(clamping: 1), vibrato: .off), playingAScore: false)

        XCTAssertEqual(hole(3, of: state)?.note, "C5")
        XCTAssertEqual(hole(3, of: state)?.effect, "(G4 overblow)")
    }

    func test_noteRow_whenTheDrawReedIsOverbent_namesTheOverdraw() {
        let harmonica = harmonica()
        _ = harmonica.play(at: [finger(at: 0.85, above: -0.3)])

        let state = presenter.present(harmonica.shapeTone(PitchShaping(clamping: 1), vibrato: .off), playingAScore: false)

        XCTAssertEqual(hole(9, of: state)?.note, "A♭6")
        XCTAssertEqual(hole(9, of: state)?.effect, "(F6 overdraw)")
    }

    func test_noteRow_whenTheBendRoundsToNoSemitone_namesOnlyTheNote() {
        let harmonica = harmonica()
        _ = harmonica.play(at: [finger(at: 0.25, above: -0.3)])

        let state = presenter.present(harmonica.shapeTone(PitchShaping(clamping: -0.1), vibrato: .off), playingAScore: false)

        XCTAssertEqual(hole(3, of: state)?.note, "B4")
        XCTAssertEqual(hole(3, of: state)?.effect, "")
    }

    func test_noteRow_whenTheKeyIsD_namesTheReedInThatKey() {
        let harmonica = harmonica()
        _ = harmonica.play(at: [finger(at: 0.05, above: 0.2)])

        let state = presenter.present(harmonica.changeKey(to: .d), playingAScore: false)

        XCTAssertEqual(hole(1, of: state)?.note, "D4")
    }

    // MARK: - Helpers

    private func harmonica() -> PlayHarmonica {
        PlayHarmonica(tuning: RichterTuning(), audioEngine: engine, log: SilentLog())
    }

    private func finger(at fromLeftEdge: Double, above centreLine: Double) -> PositionOnHarmonica {
        PositionOnHarmonica(fractionFromLeftEdge: fromLeftEdge, fractionAboveCentreLine: centreLine)
    }

    private func hole(_ number: Int, of state: HarmonicaViewState) -> HoleViewState? {
        guard case .ready(let playable) = state else { return nil }

        return playable.holes.first { $0.id == number }
    }
}
