import AVFoundation
import AudioToolbox
import HarmonicaCore

@MainActor
final class SampledAudioEngine: AudioEngineProtocol {
    nonisolated private static let amplitude: Float = 0.25
    nonisolated private static let requestedBufferSeconds = 0.001
    nonisolated private static let renderReportInterval = Duration.seconds(1)

    private let log: LogProtocol
    private var controls: ReedSamplerControls?
    private var remoteOutput: RemoteOutput?
    private var isInterrupted = false
    private var sessionObservers: [NSObjectProtocol] = []
    private var renderReporting: Task<Void, Never>?

    // MARK: - Public

    init(log: LogProtocol) {
        self.log = log
    }

    deinit {
        renderReporting?.cancel()
    }

    func prepare() async throws(AudioEngineError) {
        do {
            try await loadRecordingsIfNeeded()
            let grantedSession = try await Self.activateTheSession()
            log.record(grantedSession.description)
            try startTheOutputIfNeeded(at: grantedSession.sampleRate)
            followTheSessionOnce()
        } catch {
            log.record("audio engine failed to prepare: \(error)")
            throw Self.engineError(from: error)
        }
    }

    func soundTones(_ tones: [Tone], as change: ToneChange) {
        audibleControls?.soundTones(tones, as: change)
    }

    func changeIntensity(to intensity: BreathIntensity) {
        audibleControls?.changeIntensity(to: intensity)
    }

    func changeBend(to depth: BendDepth) {
        audibleControls?.changeBend(to: depth)
    }

    func changeVibrato(to depth: VibratoDepth) {
        audibleControls?.changeVibrato(to: depth)
    }

    func cupHands(to depth: CupDepth) {
        audibleControls?.cupHands(to: depth)
    }

    func silence(_ release: ReedRelease) {
        audibleControls?.silence(release)
    }

    // MARK: - Private

    private var audibleControls: ReedSamplerControls? {
        isInterrupted ? nil : controls
    }

    private static func engineError(from error: any Error) -> AudioEngineError {
        switch error {
        case RecordedHarmonicaError.noSamplesInTheBundle(_):
            .noRecordings
        case RecordedHarmonicaError.unreadable(let name),
             RecordedHarmonicaError.undecodable(let name, _),
             RecordedHarmonicaError.unnamedPitch(let name),
             RecordedHarmonicaError.tooShortToLoop(let name, _):
            .recordingUnreadable(name)
        default:
            .outputRefused
        }
    }

    nonisolated private static func activateTheSession() async throws -> GrantedSession {
        let requestedSeconds = requestedBufferSeconds
        return try await Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .measurement)
            try session.setPreferredIOBufferDuration(requestedSeconds)
            try session.setActive(true)
            return GrantedSession(
                sampleRate: session.sampleRate,
                bufferSeconds: session.ioBufferDuration,
                outputLatencySeconds: session.outputLatency
            )
        }.value
    }

    nonisolated private static func interruptionType(of notification: Notification) -> AVAudioSession.InterruptionType? {
        guard let interruptionTypeNumber = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return nil
        }

        return AVAudioSession.InterruptionType(rawValue: interruptionTypeNumber)
    }

    private func loadRecordingsIfNeeded() async throws {
        guard controls == nil else { return }

        let samples = try await Task.detached(priority: .userInitiated) { try RecordedHarmonica.bank() }.value
        controls = ReedSamplerControls(sampler: ReedSampler(samples: samples, log: log))
        log.record("loaded \(samples.notes.count) recorded notes")
    }

    private func startTheOutputIfNeeded(at sampleRate: Double) throws {
        guard remoteOutput == nil, let controls else {
            log.record("the output was already running")
            return
        }

        let startedOutput = try RemoteOutput(
            feeding: controls.sampler,
            sampleRate: sampleRate,
            amplitude: Self.amplitude
        )
        try startedOutput.start()
        remoteOutput = startedOutput
        log.record("remote I/O output started at \(sampleRate) Hz")
        reportTheRenderEverySecond(from: controls.sampler.health)
    }

    private func reportTheRenderEverySecond(from health: RenderHealth) {
        guard renderReporting == nil else { return }

        renderReporting = Task { [log] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.renderReportInterval)
                Self.write(health.collect(), to: log)
            }
        }
    }

    private static func write(_ report: RenderReport, to log: LogProtocol) {
        if report.hasTroubleThatCanBeHeard {
            log.record(report.description)
        } else if report.soundedSomething {
            log.recordSample(report.description)
        }
    }

    private func followTheSessionOnce() {
        guard sessionObservers.isEmpty else { return }

        let center = NotificationCenter.default
        sessionObservers = [
            center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) {
                [weak self] notification in
                guard let engine = self else { return }

                let interruptionType = Self.interruptionType(of: notification)
                MainActor.assumeIsolated { engine.interrupted(interruptionType) }
            },
            center.addObserver(
                forName: AVAudioSession.mediaServicesWereResetNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let engine = self else { return }

                MainActor.assumeIsolated { engine.mediaServicesWereReset() }
            }
        ]
    }

    private func interrupted(_ interruptionType: AVAudioSession.InterruptionType?) {
        switch interruptionType {
        case .began:
            isInterrupted = true
            log.record("audio interrupted, the output stopped and touches are not sounded until it ends")
        case .ended:
            Task { await resumeAfterTheInterruption() }
        case nil:
            log.record("an audio interruption arrived without saying whether it began or ended")
        @unknown default:
            log.record("an audio interruption of an unknown kind arrived, nothing changed")
        }
    }

    private func resumeAfterTheInterruption() async {
        do {
            let grantedSession = try await Self.activateTheSession()
            controls?.silence(.damped)
            try remoteOutput?.start()
            isInterrupted = false
            log.record("audio interruption ended, the output restarted; \(grantedSession.description)")
        } catch {
            log.record("the output could not restart after an interruption: \(error)")
        }
    }

    private func mediaServicesWereReset() {
        log.record("media services were reset, rebuilding the output")
        remoteOutput = nil
        Task {
            do {
                let grantedSession = try await Self.activateTheSession()
                controls?.silence(.damped)
                try startTheOutputIfNeeded(at: grantedSession.sampleRate)
                isInterrupted = false
            } catch {
                log.record("the output could not be rebuilt after media services were reset: \(error)")
            }
        }
    }
}

// MARK: - SampledAudioEngineError

enum SampledAudioEngineError: Error {
    case noRemoteIO
    case unsupportedOutputSampleRate(Double)
    case outputRefused(step: String, status: OSStatus)
}

// MARK: - GrantedSession

private struct GrantedSession: Sendable, CustomStringConvertible {
    let sampleRate: Double
    let bufferSeconds: Double
    let outputLatencySeconds: Double

    var description: String {
        let frames = Int((bufferSeconds * sampleRate).rounded())
        return "audio session at \(sampleRate) Hz in measurement mode, a buffer of \(frames) frames"
            + " (\(milliseconds(bufferSeconds)) ms) and \(milliseconds(outputLatencySeconds)) ms out to the speaker"
    }

    private func milliseconds(_ seconds: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), seconds * 1000)
    }
}

// MARK: - RemoteOutput

private final class RemoteOutput {
    private static let outputBus: AudioUnitElement = 0
    private static let speakerChannels: AVAudioChannelCount = 2

    private let unit: AudioUnit
    private let feed: Unmanaged<ReedFeed>

    // MARK: - Public

    init(feeding sampler: ReedSampler, sampleRate: Double, amplitude: Float) throws(SampledAudioEngineError) {
        var remoteIODescription = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        guard let remoteIOComponent = AudioComponentFindNext(nil, &remoteIODescription) else { throw .noRemoteIO }

        var createdUnit: AudioUnit?
        try Self.throwIfRefused(
            AudioComponentInstanceNew(remoteIOComponent, &createdUnit),
            while: "creating the remote I/O unit"
        )
        guard let createdUnit else { throw .noRemoteIO }

        unit = createdUnit
        feed = Unmanaged.passRetained(ReedFeed(sampler: sampler, sampleRate: sampleRate, amplitude: amplitude))
        try Self.describeTheStream(to: createdUnit, sampleRate: sampleRate)
        try Self.attach(feed, to: createdUnit)
        try Self.throwIfRefused(AudioUnitInitialize(createdUnit), while: "initialising the remote I/O unit")
    }

    deinit {
        AudioOutputUnitStop(unit)
        AudioUnitUninitialize(unit)
        AudioComponentInstanceDispose(unit)
        feed.release()
    }

    func start() throws(SampledAudioEngineError) {
        try Self.throwIfRefused(AudioOutputUnitStart(unit), while: "starting the remote I/O unit")
    }

    // MARK: - Private

    private static func describeTheStream(to unit: AudioUnit, sampleRate: Double) throws(SampledAudioEngineError) {
        guard let speakerFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: speakerChannels) else {
            throw .unsupportedOutputSampleRate(sampleRate)
        }

        var speakerStream = speakerFormat.streamDescription.pointee
        try throwIfRefused(
            AudioUnitSetProperty(
                unit,
                kAudioUnitProperty_StreamFormat,
                kAudioUnitScope_Input,
                outputBus,
                &speakerStream,
                UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
            ),
            while: "describing the stream the sampler writes"
        )
    }

    private static func attach(_ feed: Unmanaged<ReedFeed>, to unit: AudioUnit) throws(SampledAudioEngineError) {
        var renderCallback = AURenderCallbackStruct(inputProc: feedTheSpeaker, inputProcRefCon: feed.toOpaque())
        try throwIfRefused(
            AudioUnitSetProperty(
                unit,
                kAudioUnitProperty_SetRenderCallback,
                kAudioUnitScope_Input,
                outputBus,
                &renderCallback,
                UInt32(MemoryLayout<AURenderCallbackStruct>.size)
            ),
            while: "attaching the sampler to the remote I/O unit"
        )
    }

    private static func throwIfRefused(_ status: OSStatus, while step: String) throws(SampledAudioEngineError) {
        guard status != noErr else { return }

        throw .outputRefused(step: step, status: status)
    }
}

// MARK: - ReedFeed

private final class ReedFeed: Sendable {
    let sampler: ReedSampler
    let sampleRate: Double
    let amplitude: Float

    init(sampler: ReedSampler, sampleRate: Double, amplitude: Float) {
        self.sampler = sampler
        self.sampleRate = sampleRate
        self.amplitude = amplitude
    }
}

// MARK: - Render callback

private func feedTheSpeaker(
    _ context: UnsafeMutableRawPointer,
    _ flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    _ timeStamp: UnsafePointer<AudioTimeStamp>,
    _ bus: UInt32,
    _ frameCount: UInt32,
    _ buffers: UnsafeMutablePointer<AudioBufferList>?
) -> OSStatus {
    guard let buffers else { return noErr }

    let feed = Unmanaged<ReedFeed>.fromOpaque(context).takeUnretainedValue()
    let started = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    feed.sampler.render(
        frameCount: Int(frameCount),
        sampleRate: feed.sampleRate,
        amplitude: feed.amplitude,
        into: UnsafeMutableAudioBufferListPointer(buffers)
    )
    feed.sampler.health.recordBuffer(
        tookNanoseconds: clock_gettime_nsec_np(CLOCK_UPTIME_RAW) - started,
        periodNanoseconds: UInt64(Double(frameCount) / feed.sampleRate * 1_000_000_000)
    )
    return noErr
}
