import XCTest
@testable import HarmonicaCore

final class ReadScoreUseCaseUnitTests: XCTestCase {
    private let header = "key C\nposition first\ntempo 120\n"
    private let readScore = ReadScoreUseCase(tuning: RichterTuning())

    // MARK: - Tests

    func test_writtenScore_whenANoteIsPlainOnTheHarmonica_playsItWithoutAnEffect() throws {
        let reading = try readScore.read(header + "C5 1", named: "test")

        XCTAssertEqual(firstNote(of: reading)?.holes, [.four], "hole 4 blows C5")
        XCTAssertEqual(firstNote(of: reading)?.breath, .blow)
        XCTAssertEqual(reading.playability.bends, 0)
    }

    func test_writtenScore_whenANoteNeedsABend_bendsTheReedThatReachesIt() throws {
        let reading = try readScore.read(header + "Db5 1", named: "test")

        XCTAssertEqual(firstNote(of: reading)?.holes, [.four], "hole 4 draws D5, a semitone above")
        XCTAssertEqual(firstNote(of: reading)?.breath, .draw)
        XCTAssertEqual(firstNote(of: reading)?.bentBySemitones, 1)
    }

    func test_writtenScore_whenPitchesShareALine_playsThemAsOneChord() throws {
        let reading = try readScore.read(header + "C5+E5+G5 1", named: "test")

        XCTAssertEqual(firstNote(of: reading)?.holes, [.four, .five, .six])
    }

    func test_writtenScore_whenANoteIsOutOfTheHarmonicasReach_reportsIt() throws {
        let reading = try readScore.read(header + "D7 1", named: "test")

        XCTAssertEqual(reading.playability.unreachable.map(\.name), ["D7"], "a C harmonica stops at C7")
    }

    func test_writtenScore_whenItIsInGAndSecondPosition_callsForTheHarmonicaInC() throws {
        let reading = try readScore.read("key G\nposition second\ntempo 96\nG4 1", named: "test")

        XCTAssertEqual(reading.score.harmonicaKey, .c)
    }

    func test_writtenScore_whenTheTempoIsMissing_saysWhichHeaderItNeeded() throws {
        XCTAssertThrowsError(try readScore.read("key C\nposition first\nC5 1", named: "test")) { error in
            guard case ScoreTextError.missingHeader(let name) = error else { return XCTFail("\(error)") }

            XCTAssertEqual(name, "tempo")
        }
    }

    // MARK: - Helpers

    private func firstNote(of reading: ScoreReading) -> ScoreNote? {
        guard case .note(let note) = reading.score.events.first else { return nil }

        return note
    }
}
