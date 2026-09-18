import AVFoundation

final class SampledAudioEngine: AudioEngineProtocol {
    private static let amplitude: Float = 0.25
    private static let slideCrossfadeSeconds = 0.02
    private static let newReedCrossfadeSeconds = 0.05

    private let engine = AVAudioEngine()
    private let log: LogProtocol
    private var oscillator: Oscillator?
    private var sourceNode: AVAudioSourceNode?

    // MARK: - Public

    init(log: LogProtocol) {
        self.log = log
    }

    func prepare() async throws {
        do {
            try loadRecordingsIfNeeded()
            try await configureAudioSession()
            try connectOscillatorIfNeeded()
            try startEngineIfNeeded()
        } catch {
            log.record("audio engine failed to prepare: \(error)")
            throw error
        }
    }

    func soundTones(_ tones: [Tone], as change: ToneChange) {
        oscillator?.sound(
            tones.map(Self.sounding),
            over: Self.crossfadeSeconds(for: change),
            everyReedSpeaksAgain: change == .breathReversed
        )
    }

    func changeIntensity(to intensity: BreathIntensity) {
        oscillator?.changeBreathGain(to: intensity.gain)
    }

    func changeBend(to depth: BendDepth) {
        oscillator?.changeBend(to: depth.fraction)
    }

    func changeVibrato(to depth: VibratoDepth) {
        oscillator?.changeVibrato(to: depth.fraction)
    }

    func cupHands(to depth: CupDepth) {
        oscillator?.cupHands(to: depth.fraction)
    }

    func silence() {
        oscillator?.silence()
    }

    // MARK: - Private

    private static func crossfadeSeconds(for change: ToneChange) -> Double {
        switch change {
        case .slide, .breathReversed: slideCrossfadeSeconds
        case .newReed: newReedCrossfadeSeconds
        }
    }

    private static func sounding(_ tone: Tone) -> SoundingTone {
        SoundingTone(
            hertz: tone.pitch.converted(to: .hertz).value,
            bendableSemitones: tone.bendableSemitones
        )
    }

    private func loadRecordingsIfNeeded() throws {
        guard oscillator == nil else { return }

        let samples = try RecordedHarmonica.bank()
        oscillator = Oscillator(samples: samples)
        log.record("loaded \(samples.notes.count) recorded notes")
    }

    private func configureAudioSession() async throws {
        try await Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        }.value
    }

    private func connectOscillatorIfNeeded() throws {
        guard sourceNode == nil, let oscillator else {
            log.record("oscillator was already connected")
            return
        }

        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw SampledAudioEngineError.unsupportedOutputSampleRate(sampleRate)
        }

        let node = makeSourceNode(oscillator, format: format, sampleRate: sampleRate)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node
        log.record("oscillator connected at \(sampleRate) Hz")
    }

    private func startEngineIfNeeded() throws {
        guard !engine.isRunning else {
            log.record("audio engine was already running")
            return
        }

        try engine.start()
        log.record("audio engine started")
    }

    private func makeSourceNode(
        _ oscillator: Oscillator,
        format: AVAudioFormat,
        sampleRate: Double
    ) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { [amplitude = Self.amplitude] _, _, frameCount, audioBufferList in
            oscillator.render(
                frameCount: Int(frameCount),
                sampleRate: sampleRate,
                amplitude: amplitude,
                into: UnsafeMutableAudioBufferListPointer(audioBufferList)
            )
            return noErr
        }
    }
}

// MARK: - SampledAudioEngineError

enum SampledAudioEngineError: Error {
    case unsupportedOutputSampleRate(Double)
}
