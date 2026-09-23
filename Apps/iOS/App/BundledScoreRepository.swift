import Foundation
import HarmonicaCore

struct BundledScoreRepository {
    static let folder = "Scores"

    private let tuning: RichterTuning
    private let log: LogProtocol

    // MARK: - Public

    init(tuning: RichterTuning, log: LogProtocol) {
        self.tuning = tuning
        self.log = log
    }

    func first() -> Score? {
        guard let url = firstURL() else {
            log.record("no score file bundled, the demo plays the built in blues")
            return nil
        }

        do {
            return try read(url)
        } catch {
            log.record("could not read \(url.lastPathComponent): \(error), the demo plays the built in blues")
            return nil
        }
    }

    // MARK: - Private

    private func firstURL() -> URL? {
        (Bundle.main.urls(forResourcesWithExtension: "score", subdirectory: Self.folder) ?? [])
            .min { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func read(_ url: URL) throws -> Score {
        let reading = try ReadScoreUseCase(tuning: tuning).read(
            String(contentsOf: url, encoding: .utf8),
            named: url.deletingPathExtension().lastPathComponent
        )
        log.record(
            "read \(url.lastPathComponent) in \(reading.score.key), \(reading.score.position) position,"
            + " on a harmonica in \(reading.score.harmonicaKey): \(Self.describe(reading.playability))"
        )
        return reading.score
    }

    private static func describe(_ playability: Playability) -> String {
        "\(playability.bends) bends, \(playability.overbends) overbends,"
            + " widest leap \(playability.widestLeapInHoles) holes, "
            + describe(unreachable: playability.unreachable)
    }

    private static func describe(unreachable notes: [MIDINote]) -> String {
        guard !notes.isEmpty else { return "every note reachable" }

        return "out of reach: " + notes.map(\.name).joined(separator: " ")
    }
}
