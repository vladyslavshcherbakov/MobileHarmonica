import XCTest
@testable import HarmonicaCore
import HarmonicaCoreTestSupport

final class WhatAWrittenScoreBecomesTests: XCTestCase {
    private let reader = ScoreReader(tuning: RichterTuning())

    // MARK: - Tests

    func test_writtenScore_whenANoteIsPlainOnTheHarmonica_playsItWithoutAnEffect() throws {
        let read = try reader.read(header + "C5 1", named: "test")

        XCTAssertEqual(firstNote(of: read)?.holes, [.four], "hole 4 blows C5")
        XCTAssertEqual(firstNote(of: read)?.breath, .blow)
        XCTAssertEqual(read.playability.bends, 0)
    }

    func test_writtenScore_whenANoteNeedsABend_bendsTheReedThatReachesIt() throws {
        let read = try reader.read(header + "Db5 1", named: "test")

        XCTAssertEqual(firstNote(of: read)?.holes, [.four], "hole 4 draws D5, a semitone above")
        XCTAssertEqual(firstNote(of: read)?.breath, .draw)
        XCTAssertEqual(firstNote(of: read)?.bentBySemitones, 1)
    }

    func test_writtenScore_whenPitchesShareALine_playsThemAsOneChord() throws {
        let read = try reader.read(header + "C5+E5+G5 1", named: "test")

        XCTAssertEqual(firstNote(of: read)?.holes, [.four, .five, .six])
    }

    func test_writtenScore_whenANoteIsOutOfTheHarmonicasReach_reportsIt() throws {
        let read = try reader.read(header + "D7 1", named: "test")

        XCTAssertEqual(read.playability.unreachable.map(\.name), ["D7"], "a C harmonica stops at C7")
    }

    func test_writtenScore_whenItIsInGAndSecondPosition_callsForTheHarmonicaInC() throws {
        let read = try reader.read("key G\nposition second\ntempo 96\nG4 1", named: "test")

        XCTAssertEqual(read.score.harmonicaKey, .c)
    }

    func test_writtenScore_whenTheTempoIsMissing_saysWhichHeaderItNeeded() throws {
        XCTAssertThrowsError(try reader.read("key C\nposition first\nC5 1", named: "test")) { error in
            guard case ScoreTextError.missingHeader(let name) = error else { return XCTFail("\(error)") }

            XCTAssertEqual(name, "tempo")
        }
    }

    // MARK: - Helpers

    private let header = "key C\nposition first\ntempo 120\n"

    private func firstNote(of read: ReadScore) -> ScoreNote? {
        guard case .note(let note) = read.score.events.first else { return nil }

        return note
    }
}
