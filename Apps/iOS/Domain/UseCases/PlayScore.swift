import Foundation

final class PlayScore {
    private static let articulationSeconds = 0.05
    private static let slideStepSeconds = 0.04
    private static let shakeStepSeconds = 0.06
    private static let bendStepSeconds = 0.01

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
            continuation.yield(harmonica.play([hole], breathing: note.breath))
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
        let sounding = seconds - gap
        let steps = Self.steps(of: note, within: sounding)
        let started = ContinuousClock.now
        for step in 0..<steps {
            _ = harmonica.shapeTone(
                shaping(for: note, at: Self.fraction(step, of: steps)),
                vibrato: VibratoDepth(clamping: note.vibrato)
            )
            continuation.yield(harmonica.play(Self.holes(of: note, at: step), breathing: note.breath))
            await wait(until: started, plus: sounding * Double(step + 1) / Double(steps))
        }
        continuation.yield(harmonica.stopPlaying())
        await wait(gap)
    }

    private static func steps(of note: ScoreNote, within seconds: Double) -> Int {
        guard let step = stepSeconds(of: note) else { return 1 }

        return max(1, Int(seconds / step))
    }

    private static func stepSeconds(of note: ScoreNote) -> Double? {
        if note.shakenWith != nil { return shakeStepSeconds }

        return note.bendEndsAtSemitones == nil ? nil : bendStepSeconds
    }

    private static func fraction(_ step: Int, of steps: Int) -> Double {
        steps > 1 ? Double(step) / Double(steps - 1) : 0
    }

    private func wait(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(max(0, seconds)))
    }

    private func wait(until started: ContinuousClock.Instant, plus seconds: Double) async {
        try? await Task.sleep(until: started + .seconds(max(0, seconds)), clock: ContinuousClock())
    }

    private func shaping(for note: ScoreNote, at fraction: Double) -> PitchShaping {
        guard !note.isOverbent else { return PitchShaping(clamping: 1) }

        let semitones = Self.bend(of: note, at: fraction)
        let range = note.holes
            .map { tuning.bendableSemitones(for: Reed(hole: $0, breath: note.breath)) }
            .max() ?? 0
        guard semitones > 0, range > 0 else { return .rest }

        return PitchShaping(clamping: -semitones / range)
    }

    private static func bend(of note: ScoreNote, at fraction: Double) -> Double {
        guard let ending = note.bendEndsAtSemitones else { return note.bentBySemitones }

        return note.bentBySemitones + (ending - note.bentBySemitones) * fraction
    }

    private static func passingHoles(of note: ScoreNote) -> [Hole] {
        guard let from = note.slideFrom, let arriving = note.holes.first, from != arriving else { return [] }

        let numbers = from.number < arriving.number
            ? Array(from.number..<arriving.number)
            : Array((arriving.number + 1...from.number).reversed())
        return numbers.compactMap(Hole.init(rawValue:))
    }

    private static func holes(of note: ScoreNote, at step: Int) -> [Hole] {
        guard let shaken = note.shakenWith, !step.isMultiple(of: 2) else { return note.holes }

        return [shaken]
    }
}
