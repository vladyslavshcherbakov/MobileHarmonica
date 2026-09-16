import AVFoundation

final class SineWaveAudioEngine: AudioEngineProtocol {
    private static let amplitude: Float = 0.25

    private let engine = AVAudioEngine()
    private let oscillator = Oscillator()
    private let log: TimestampedLog
    private var sourceNode: AVAudioSourceNode?

    // MARK: - Public

    init(log: TimestampedLog) {
        self.log = log
    }

    func prepare() async throws {
        do {
            try await configureAudioSession()
            try connectOscillatorIfNeeded()
            try startEngineIfNeeded()
        } catch {
            log.record("audio engine failed to prepare: \(error)")
            throw error
        }
    }

    func soundTones(_ tones: [Tone]) {
        oscillator.sound(tones.map(Self.sounding))
    }

    func changeIntensity(to intensity: BreathIntensity) {
        oscillator.changeBreathGain(to: intensity.gain)
    }

    func changeBend(to depth: BendDepth) {
        oscillator.changeBend(to: depth.fraction)
    }

    func changeVibrato(to depth: VibratoDepth) {
        oscillator.changeVibrato(to: depth.fraction)
    }

    func silence() {
        oscillator.silence()
    }

    // MARK: - Private

    private static func sounding(_ tone: Tone) -> SoundingTone {
        SoundingTone(
            hertz: tone.pitch.converted(to: .hertz).value,
            bendableSemitones: tone.bendableSemitones
        )
    }

    private func configureAudioSession() async throws {
        try await Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        }.value
    }

    private func connectOscillatorIfNeeded() throws {
        guard sourceNode == nil else {
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
            throw SineWaveAudioEngineError.unsupportedOutputSampleRate(sampleRate)
        }

        let node = makeSourceNode(format: format, sampleRate: sampleRate)
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

    private func makeSourceNode(format: AVAudioFormat, sampleRate: Double) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { [oscillator, amplitude = Self.amplitude] _, _, frameCount, audioBufferList in
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

// MARK: - SineWaveAudioEngineError

enum SineWaveAudioEngineError: Error {
    case unsupportedOutputSampleRate(Double)
}
