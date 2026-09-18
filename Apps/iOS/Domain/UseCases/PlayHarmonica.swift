import Foundation

final class PlayHarmonica {
    private let tuning: RichterTuning
    private let audioEngine: AudioEngineProtocol
    private let log: LogProtocol
    private var soundingReeds: [Reed] = []
    private var soundingIntensity: BreathIntensity?
    private var bend: BendDepth = .unbent
    private var vibrato: VibratoDepth = .off
    private var recordedMouthWidth = ""
    private var key: HarmonicaKey = .c
    private var style: PlayingStyle = .fingers

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
        let reeds = reedsUnder(sounding)
        guard !reeds.isEmpty, let intensity = intensityOf(sounding) else { return stopPlaying() }

        applyBreathIntensity(intensity)
        recordMouthWidth(of: sounding)
        guard reeds != soundingReeds else { return harmonica }

        sound(reeds)
        return harmonica
    }

    func changeStyle(to style: PlayingStyle) -> Harmonica {
        guard style != self.style else { return harmonica }

        self.style = style
        log.record("playing style changed to \(style)")
        return stopPlaying()
    }

    func changeKey(to key: HarmonicaKey) -> Harmonica {
        self.key = key
        log.record("key changed to \(key), \(key.semitonesFromC) semitones from C")
        guard !soundingReeds.isEmpty else { return harmonica }

        sound(soundingReeds)
        return harmonica
    }

    func shapeTone(bend: BendDepth, vibrato: VibratoDepth) -> Harmonica {
        guard bend != self.bend || vibrato != self.vibrato else { return harmonica }

        self.bend = bend
        self.vibrato = vibrato
        log.recordSample("bend \(rounded(bend.fraction)) of \(rounded(bendableSemitones)) semitones, vibrato \(rounded(vibrato.fraction))")
        audioEngine.changeBend(to: bend)
        audioEngine.changeVibrato(to: vibrato)
        return harmonica
    }

    func stopPlaying() -> Harmonica {
        guard !soundingReeds.isEmpty else { return harmonica }

        audioEngine.silence()
        log.record("silent, \(describe(soundingReeds)) released")
        soundingReeds = []
        soundingIntensity = nil
        return harmonica
    }

    // MARK: - Private

    private var harmonica: Harmonica {
        Harmonica(
            key: key,
            style: style,
            sounding: Dictionary(uniqueKeysWithValues: soundingReeds.map { ($0.hole, soundingReed(of: $0)) })
        )
    }

    private var bendableSemitones: Double {
        soundingReeds.map(tuning.bendableSemitones(for:)).max() ?? 0
    }

    private func soundingReed(of reed: Reed) -> SoundingReed {
        SoundingReed(
            unbent: tuning.note(for: reed, in: key),
            bendableSemitones: tuning.bendableSemitones(for: reed),
            bend: bend
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
        switch style {
        case .fingers:
            Set(positions.compactMap(Hole.init(at:))).sorted { $0.number < $1.number }
        case .mouth:
            PositionOnHarmonica.topmost(of: positions).map(Hole.allCovered(by:)) ?? []
        }
    }

    private func recordMouthWidth(of positions: [PositionOnHarmonica]) {
        guard style == .mouth, let mouth = PositionOnHarmonica.topmost(of: positions) else { return }

        let width = rounded(mouth.coveredHoleWidths)
        guard width != recordedMouthWidth else { return }

        recordedMouthWidth = width
        log.recordSample("mouth \(width) holes wide")
    }

    private func sound(_ reeds: [Reed]) {
        let tones = reeds.map { tuning.tone(for: $0, in: key) }
        audioEngine.soundTones(tones)
        soundingReeds = reeds
        log.record("sounding \(describe(reeds)) in key \(key)")
    }

    private func describe(_ reeds: [Reed]) -> String {
        reeds
            .map { "hole \($0.hole.number) \($0.breath) \(rounded(tuning.tone(for: $0, in: key).pitch.converted(to: .hertz).value)) Hz" }
            .joined(separator: ", ")
    }

    private func rounded(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
