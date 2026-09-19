import Foundation

final class PlayHarmonica {
    private let tuning: RichterTuning
    private let audioEngine: AudioEngineProtocol
    private let log: LogProtocol
    private var soundingReeds: [Reed] = []
    private var soundingIntensity: BreathIntensity?
    private var shaping: PitchShaping = .rest
    private var vibrato: VibratoDepth = .off
    private var cup: CupDepth = .open
    private var recordedMouthWidth = ""
    private var key: HarmonicaKey = .c
    private var style: PlayingStyle = .severalFingersSeveralNotes

    // MARK: - Public

    init(tuning: RichterTuning, audioEngine: AudioEngineProtocol, log: LogProtocol) {
        self.tuning = tuning
        self.audioEngine = audioEngine
        self.log = log
    }

    func prepare() async throws -> Harmonica {
        try await audioEngine.prepare()
        log.record("harmonica ready in key \(key)")
        return harmonica
    }

    func play(at positions: [PositionOnHarmonica]) -> Harmonica {
        let sounding = positions.filter(\.isOnTheHarmonica)
        guard !isCrossingTheBreathBoundary(sounding) else { return harmonica }

        let reeds = reedsUnder(sounding)
        guard !reeds.isEmpty, let intensity = intensityOf(sounding) else { return stopPlaying(.ringsDown) }

        applyBreathIntensity(intensity)
        recordMouthWidth(of: sounding)
        guard reeds != soundingReeds else { return harmonica }

        sound(reeds, as: breathTurns(into: reeds) ? .breathReversed : .slide)
        return harmonica
    }

    func play(_ holes: [Hole], breathing breath: Breath) -> Harmonica {
        let reeds = holes.map { Reed(hole: $0, breath: breath) }
        applyBreathIntensity(.full)
        guard reeds != soundingReeds else { return harmonica }

        sound(reeds, as: breathTurns(into: reeds) ? .breathReversed : .slide)
        return harmonica
    }

    func changeStyle(to style: PlayingStyle) -> Harmonica {
        guard style != self.style else { return harmonica }

        self.style = style
        log.record("playing style changed to \(style)")
        return stopPlaying(.ringsDown)
    }

    func changeKey(to key: HarmonicaKey) -> Harmonica {
        self.key = key
        log.record("key changed to \(key), \(key.semitonesFromC) semitones from C")
        guard !soundingReeds.isEmpty else { return harmonica }

        sound(soundingReeds, as: .slide)
        return harmonica
    }

    func shapeTone(_ shaping: PitchShaping, vibrato: VibratoDepth) -> Harmonica {
        guard shaping != self.shaping || vibrato != self.vibrato else { return harmonica }

        let wasOverbent = overbend
        self.shaping = shaping
        self.vibrato = vibrato
        log.recordSample("bend \(rounded(bend.fraction)) of \(rounded(semitonesTheMouthCanPull)) semitones, overbend \(rounded(overbend.fraction)) of \(rounded(overbendableSemitones)) semitones, vibrato \(rounded(vibrato.fraction))")
        audioEngine.changeBend(to: bend)
        audioEngine.changeVibrato(to: vibrato)
        guard overbend != wasOverbent, !soundingReeds.isEmpty else { return harmonica }

        sound(soundingReeds, as: .newReed)
        return harmonica
    }

    func cupHands(to cup: CupDepth) -> Harmonica {
        guard cup != self.cup else { return harmonica }

        self.cup = cup
        audioEngine.cupHands(to: cup)
        log.recordSample("hands cupped \(rounded(cup.fraction))")
        return harmonica
    }

    func stopPlaying(_ release: ReedRelease) -> Harmonica {
        guard !soundingReeds.isEmpty else { return harmonica }

        audioEngine.silence(release)
        log.record("silent, \(describe(soundingReeds)) \(release)")
        soundingReeds = []
        soundingIntensity = nil
        return harmonica
    }

    // MARK: - Private

    private var harmonica: Harmonica {
        Harmonica(
            key: key,
            style: style,
            cup: cup,
            sounding: Dictionary(uniqueKeysWithValues: soundingReeds.map { ($0.hole, soundingReed(of: $0)) })
        )
    }

    private var bend: BendDepth {
        shaping.bend
    }

    private var overbend: OverbendDepth {
        shaping.overbend
    }

    private var semitonesTheMouthCanPull: Double {
        soundingReeds.map(tuning.bendableSemitones(for:)).min() ?? 0
    }

    private var overbendableSemitones: Double {
        soundingReeds.map(tuning.overbendableSemitones(for:)).max() ?? 0
    }

    private func soundingReed(of reed: Reed) -> SoundingReed {
        SoundingReed(
            breath: reed.breath,
            unbent: tuning.note(for: reed, in: key),
            bendableSemitones: semitonesTheMouthCanPull,
            overbendableSemitones: tuning.overbendableSemitones(for: reed),
            bend: bend,
            overbend: overbend
        )
    }

    private func intensityOf(_ positions: [PositionOnHarmonica]) -> BreathIntensity? {
        PositionOnHarmonica.topmost(of: positions).map(BreathIntensity.init(at:))
    }

    private func applyBreathIntensity(_ intensity: BreathIntensity) {
        guard intensity != soundingIntensity else { return }

        audioEngine.changeIntensity(to: intensity)
        soundingIntensity = intensity
        log.recordSample("breath intensity \(rounded(intensity.gain))")
    }

    private func reedsUnder(_ positions: [PositionOnHarmonica]) -> [Reed] {
        guard let breath = Breath(topmostOf: positions) else { return [] }

        return holesUnder(positions).map { Reed(hole: $0, breath: breath) }
    }

    private func holesUnder(_ positions: [PositionOnHarmonica]) -> [Hole] {
        Set(fingersThatSound(among: positions).flatMap(holesCovered(by:))).sorted { $0.number < $1.number }
    }

    private func fingersThatSound(among positions: [PositionOnHarmonica]) -> [PositionOnHarmonica] {
        guard style.takesTheTopmostFingerOnly else { return positions }

        return PositionOnHarmonica.topmost(of: positions).map { [$0] } ?? []
    }

    private func holesCovered(by position: PositionOnHarmonica) -> [Hole] {
        guard style.coversTheContactWidth else { return Hole(at: position).map { [$0] } ?? [] }

        return Hole.allCovered(by: position)
    }

    private func isCrossingTheBreathBoundary(_ positions: [PositionOnHarmonica]) -> Bool {
        guard !soundingReeds.isEmpty, let topmost = PositionOnHarmonica.topmost(of: positions) else { return false }

        return topmost.isCrossingTheBreathBoundary
    }

    private func breathTurns(into reeds: [Reed]) -> Bool {
        guard let sounding = soundingReeds.first?.breath, let arriving = reeds.first?.breath else { return false }

        return sounding != arriving
    }

    private func recordMouthWidth(of positions: [PositionOnHarmonica]) {
        guard style.coversTheContactWidth, let mouth = PositionOnHarmonica.topmost(of: positions) else { return }

        let width = rounded(mouth.coveredHoleWidths)
        guard width != recordedMouthWidth else { return }

        recordedMouthWidth = width
        log.recordSample("mouth \(width) holes wide")
    }

    private func sound(_ reeds: [Reed], as change: ToneChange) {
        soundingReeds = reeds
        audioEngine.soundTones(reeds.map { soundingReed(of: $0).tone }, as: change)
        log.record("sounding \(describe(reeds)) in key \(key)")
    }

    private func describe(_ reeds: [Reed]) -> String {
        reeds
            .map { "hole \($0.hole.number) \($0.breath) \(rounded(soundingReed(of: $0).tone.pitch.converted(to: .hertz).value)) Hz" }
            .joined(separator: ", ")
    }

    private func rounded(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
