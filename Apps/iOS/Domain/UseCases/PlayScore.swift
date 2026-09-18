import Foundation

final class PlayScore {
    private static let articulationSeconds = 0.05
    private static let slideStepSeconds = 0.04

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
        log.record("score started in \(score.key), \(score.position) position, calling for a harmonica in \(score.harmonicaKey)")
        continuation.yield(harmonica.changeKey(to: score.harmonicaKey))
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

        let slid = await slide(into: note, within: seconds, into: continuation)
        await sound(note, for: seconds - slid, into: continuation)
    }

    private func slide(
        into note: ScoreNote,
        within seconds: Double,
        into continuation: AsyncStream<Harmonica>.Continuation
    ) async -> Double {
        let passing = Self.passingHoles(of: note)
        guard !passing.isEmpty else { return 0 }

        let step = min(Self.slideStepSeconds, seconds / 2 / Double(passing.count))
        continuation.yield(harmonica.shapeTone(.rest, vibrato: .off))
        for hole in passing {
            continuation.yield(harmonica.play(at: [Self.position(of: hole, breathing: note.breath)]))
            await wait(step)
        }
        return step * Double(passing.count)
    }

    private func sound(
        _ note: ScoreNote,
        for seconds: Double,
        into continuation: AsyncStream<Harmonica>.Continuation
    ) async {
        let gap = min(Self.articulationSeconds, seconds / 4)
        continuation.yield(harmonica.shapeTone(shaping(for: note), vibrato: VibratoDepth(clamping: note.vibrato)))
        continuation.yield(harmonica.play(at: Self.positions(of: note)))
        await wait(seconds - gap)
        continuation.yield(harmonica.stopPlaying())
        await wait(gap)
    }

    private func wait(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(max(0, seconds)))
    }

    private func shaping(for note: ScoreNote) -> PitchShaping {
        guard !note.isOverbent else { return PitchShaping(clamping: 1) }

        let range = note.holes
            .map { tuning.bendableSemitones(for: Reed(hole: $0, breath: note.breath)) }
            .max() ?? 0
        guard note.bentBySemitones > 0, range > 0 else { return .rest }

        return PitchShaping(clamping: -note.bentBySemitones / range)
    }

    private static func passingHoles(of note: ScoreNote) -> [Hole] {
        guard let from = note.slideFrom, let arriving = note.holes.first, from != arriving else { return [] }

        let numbers = from.number < arriving.number
            ? Array(from.number..<arriving.number)
            : Array((arriving.number + 1...from.number).reversed())
        return numbers.compactMap(Hole.init(rawValue:))
    }

    private static func positions(of note: ScoreNote) -> [PositionOnHarmonica] {
        note.holes.map { position(of: $0, breathing: note.breath) }
    }

    private static func position(of hole: Hole, breathing breath: Breath) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: (Double(hole.number) - 0.5) / Double(Hole.allCases.count),
            fractionAboveCentreLine: breath == .blow ? 0.5 : -0.5
        )
    }
}
