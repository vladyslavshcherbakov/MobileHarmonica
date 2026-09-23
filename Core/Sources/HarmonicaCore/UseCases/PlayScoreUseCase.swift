import Foundation

@MainActor
public final class PlayScoreUseCase {
    private let tuning: RichterTuning
    private let harmonica: PlayHarmonicaUseCase
    private let log: LogProtocol

    // MARK: - Public

    nonisolated public init(tuning: RichterTuning, harmonica: PlayHarmonicaUseCase, log: LogProtocol) {
        self.tuning = tuning
        self.harmonica = harmonica
        self.log = log
    }

    public func play(_ score: Score, reporting report: (Harmonica) -> Void) async {
        log.record("score started in \(score.key), \(score.position) position, calling for a harmonica in \(score.harmonicaKey)")
        report(harmonica.changeKey(to: score.harmonicaKey))
        for event in score.events where !Task.isCancelled {
            await perform(event, secondsPerBeat: score.secondsPerBeat, reporting: report)
        }
        guard !Task.isCancelled else {
            log.record("score stopped early")
            return
        }

        report(harmonica.shapeTone(.rest, vibrato: .off))
        report(harmonica.stopPlaying(.ringsDown))
        log.record("score finished")
    }

    // MARK: - Private

    private func perform(
        _ event: ScoreEvent,
        secondsPerBeat: Double,
        reporting report: (Harmonica) -> Void
    ) async {
        let seconds = event.beats * secondsPerBeat
        guard case .note(let note) = event else {
            await wait(seconds)
            return
        }

        let slid = await slide(into: note, within: seconds, reporting: report)
        await sound(note, for: seconds - slid, reporting: report)
    }

    private func slide(
        into note: ScoreNote,
        within seconds: Double,
        reporting report: (Harmonica) -> Void
    ) async -> Double {
        let passing = Self.passingHoles(of: note)
        guard !passing.isEmpty else { return 0 }

        let step = min(ScoreTiming.slideStepSeconds, seconds / 2 / Double(passing.count))
        report(harmonica.shapeTone(.rest, vibrato: .off))
        for hole in passing where !Task.isCancelled {
            report(harmonica.play([hole], breathing: note.breath, at: Self.intensity(of: note)))
            await wait(step)
        }
        return step * Double(passing.count)
    }

    private func sound(
        _ note: ScoreNote,
        for seconds: Double,
        reporting report: (Harmonica) -> Void
    ) async {
        let gap = min(ScoreTiming.articulationSeconds, seconds / 4)
        let sounding = seconds - gap
        let steps = Self.steps(of: note, within: sounding)
        let started = ContinuousClock.now
        for step in 0..<steps where !Task.isCancelled {
            _ = harmonica.shapeTone(
                shaping(for: note, at: Self.fraction(step, of: steps)),
                vibrato: VibratoDepth(clamping: note.vibrato)
            )
            report(
                harmonica.play(Self.holes(of: note, at: step), breathing: note.breath, at: Self.intensity(of: note))
            )
            await wait(until: started, plus: sounding * Double(step + 1) / Double(steps))
        }
        guard !Task.isCancelled else { return }

        report(harmonica.stopPlaying(.damped))
        await wait(gap)
    }

    private static func intensity(of note: ScoreNote) -> BreathIntensity {
        BreathIntensity(gain: note.breathIntensity)
    }

    private static func steps(of note: ScoreNote, within seconds: Double) -> Int {
        guard let step = stepSeconds(of: note) else { return 1 }

        return max(1, Int(seconds / step))
    }

    private static func stepSeconds(of note: ScoreNote) -> Double? {
        if note.shakenWith != nil { return ScoreTiming.shakeStepSeconds }

        return note.bendEndsAtSemitones == nil ? nil : ScoreTiming.bendStepSeconds
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

        return PitchShaping(clamping: semitones / range)
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
