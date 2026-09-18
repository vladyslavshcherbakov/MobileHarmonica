import Foundation

struct BundledScores {
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
        let read = try ScoreReader(tuning: tuning).read(
            String(contentsOf: url, encoding: .utf8),
            named: url.deletingPathExtension().lastPathComponent
        )
        log.record(
            "read \(url.lastPathComponent) in \(read.score.key), \(read.score.position) position,"
            + " on a harmonica in \(read.score.harmonicaKey): \(read.playability.summary)"
        )
        return read.score
    }
}
