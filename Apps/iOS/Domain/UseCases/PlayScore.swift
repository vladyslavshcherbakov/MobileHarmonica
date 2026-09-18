import Foundation

final class PlayScore {
    private static let articulationSeconds = 0.05

    private let tuning: RichterTuning
    private let harmonica: PlayHarmonica
    private let log: LogProtocol

    // MARK: - Public

    init(tuning: RichterTuning, harmonica: PlayHarmonica, log: LogProtocol) {
        self.tuning = tuning
        self.harmonica = harmonica
        self.log = log
    }

    func play(_ score: Score) -> AsyncStream<Harmonica> {
        AsyncStream { continuation in
            let performance = Task { await perform(score, into: continuation) }
            continuation.onTermination = { _ in performance.cancel() }
        }
    }

    // MARK: - Private

    private func perform(_ score: Score, into continuation: AsyncStream<Harmonica>.Continuation) async {
        log.record("score started, \(score.events.count) events at \(score.beatsPerMinute) bpm in key \(score.key)")
        continuation.yield(harmonica.changeKey(to: score.key))
        for event in score.events where !Task.isCancelled {
            await perform(event, secondsPerBeat: score.secondsPerBeat, into: continuation)
        }
        continuation.yield(harmonica.shapeTone(.rest, vibrato: .off))
        continuation.yield(harmonica.stopPlaying())
        log.record(Task.isCancelled ? "score stopped early" : "score finished")
        continuation.finish()
    }

    private func perform(
        _ event: ScoreEvent,
        secondsPerBeat: Double,
        into continuation: AsyncStream<Harmonica>.Continuation
    ) async {
        let seconds = event.beats * secondsPerBeat
        guard case .note(let note) = event else {
            continuation.yield(harmonica.stopPlaying())
            await wait(seconds)
            return
        }

        let gap = min(Self.articulationSeconds, seconds / 4)
        continuation.yield(harmonica.shapeTone(shaping(for: note), vibrato: VibratoDepth(clamping: note.vibrato)))
        continuation.yield(harmonica.play(at: [Self.position(of: note)]))
        await wait(seconds - gap)
        continuation.yield(harmonica.stopPlaying())
        await wait(gap)
    }

    private func wait(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(max(0, seconds)))
    }

    private func shaping(for note: ScoreNote) -> PitchShaping {
        guard !note.isOverbent else { return PitchShaping(clamping: 1) }

        let range = tuning.bendableSemitones(for: Reed(hole: note.hole, breath: note.breath))
        guard note.bentBySemitones > 0, range > 0 else { return .rest }

        return PitchShaping(clamping: -note.bentBySemitones / range)
    }

    private static func position(of note: ScoreNote) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: (Double(note.hole.number) - 0.5) / Double(Hole.allCases.count),
            fractionAboveCentreLine: note.breath == .blow ? 0.5 : -0.5
        )
    }
}
