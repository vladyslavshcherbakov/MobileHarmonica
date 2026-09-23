import AVFoundation
import HarmonicaCore
import Synchronization

final class ReedSampler: @unchecked Sendable {
    private static let reedSpeaksInSeconds = 0.005
    private static let reedStopsInSeconds = 0.02
    private static let openCupHertz = 20000.0
    private static let closedCupHertz = 800.0

    private let samples: SampleBank
    private let frames: UnsafeMutableBufferPointer<Float>
    private let bank: UnsafeMutablePointer<VoiceBank>
    private let commands = ReedCommandQueue()
    private let requestedBreathGain = Atomic<UInt64>(0)
    private let requestedBend = Atomic<UInt64>(0)
    private let requestedVibrato = Atomic<UInt64>(0)
    private let requestedCup = Atomic<UInt64>(0)
    private let log: LogProtocol

    let health = RenderHealth()

    // MARK: - Public

    init(samples: SampleBank, log: LogProtocol) {
        self.samples = samples
        self.log = log
        frames = .allocate(capacity: samples.frames.count)
        _ = frames.initialize(fromContentsOf: samples.frames)
        bank = .allocate(capacity: 1)
        bank.initialize(to: VoiceBank())
    }

    deinit {
        bank.pointee.releaseTheVoices()
        bank.deinitialize(count: 1)
        bank.deallocate()
        frames.deallocate()
    }

    func sound(_ tones: [SoundingTone], over crossfadeSeconds: Double, everyReedSpeaksAgain: Bool) {
        send(
            .sound(crossfadeSeconds: crossfadeSeconds, everyReedSpeaksAgain: everyReedSpeaksAgain),
            with: recorded(tones)
        )
    }

    func changeBreathGain(to gain: Double) {
        requestedBreathGain.store(gain.bitPattern, ordering: .relaxed)
    }

    func changeBend(to fraction: Double) {
        requestedBend.store(fraction.bitPattern, ordering: .relaxed)
    }

    func changeVibrato(to fraction: Double) {
        requestedVibrato.store(fraction.bitPattern, ordering: .relaxed)
    }

    func cupHands(to fraction: Double) {
        requestedCup.store(fraction.bitPattern, ordering: .relaxed)
    }

    func ringDown() {
        send(.ringDown, with: [])
    }

    func damp() {
        send(.damp(seconds: Self.reedStopsInSeconds), with: [])
    }

    func render(
        frameCount: Int,
        sampleRate: Double,
        amplitude: Float,
        into buffers: UnsafeMutableAudioBufferListPointer
    ) {
        commands.drain { command, tones in bank.pointee.apply(command, tones: tones) }
        health.recordVoices(bank.pointee.voiceCount)
        health.recordStolenVoices(bank.pointee.takeStolenVoices())
        guard !bank.pointee.isSilent else {
            fillWithSilence(frameCount: frameCount, into: buffers)
            return
        }

        bank.pointee.bend(by: Double(bitPattern: requestedBend.load(ordering: .relaxed)))
        bank.pointee.prepareRingDown(sampleRate: sampleRate)
        let vibrato = bank.pointee.driftedVibrato(
            depth: Double(bitPattern: requestedVibrato.load(ordering: .relaxed)),
            overFrames: frameCount,
            sampleRate: sampleRate
        )
        fill(
            frameCount: frameCount,
            amplitude: amplitude,
            settings: RenderSettings(
                sampleRate: sampleRate,
                ramp: Self.gainRamp(crossfadeSeconds: bank.pointee.crossfadeSeconds, sampleRate: sampleRate),
                breathGain: Double(bitPattern: requestedBreathGain.load(ordering: .relaxed)),
                vibrato: vibrato,
                cupCoefficient: Self.cupCoefficient(
                    closed: Double(bitPattern: requestedCup.load(ordering: .relaxed)),
                    sampleRate: sampleRate
                )
            ),
            into: buffers
        )
        bank.pointee.forgetSilentVoices()
    }

    // MARK: - Private

    private static func cupCoefficient(closed: Double, sampleRate: Double) -> Double {
        let hertz = openCupHertz * pow(closedCupHertz / openCupHertz, closed)
        return 1 - exp(-radiansPerCycle * hertz / sampleRate)
    }

    private static func gainRamp(crossfadeSeconds: Double, sampleRate: Double) -> GainRamp {
        GainRamp(
            rising: gainStep(seconds: reedSpeaksInSeconds, sampleRate: sampleRate),
            falling: gainStep(seconds: crossfadeSeconds, sampleRate: sampleRate)
        )
    }

    private static func gainStep(seconds: Double, sampleRate: Double) -> Double {
        1 / (seconds * sampleRate)
    }

    private func recorded(_ tones: [SoundingTone]) -> [PlayableTone] {
        tones.compactMap { tone in
            samples.nearest(to: tone.hertz).map { (tone: tone, recorded: $0) }
        }
    }

    private func send(_ command: ReedCommand, with tones: [PlayableTone]) {
        let tonesToSend = Array(tones.prefix(ReedCommandQueue.mostTonesPerCommand))
        if tonesToSend.count < tones.count {
            log.record("\(tones.count) tones were asked for at once, the sampler sounds the first \(tonesToSend.count)")
        }
        if !commands.push(command, tones: tonesToSend) {
            log.record("the sampler has \(ReedCommandQueue.capacity) commands it has not played yet, \(command) was dropped")
        }
    }

    private func fillWithSilence(frameCount: Int, into buffers: UnsafeMutableAudioBufferListPointer) {
        for frame in 0..<frameCount {
            write(0, atFrame: frame, into: buffers)
        }
    }

    private func fill(
        frameCount: Int,
        amplitude: Float,
        settings: RenderSettings,
        into buffers: UnsafeMutableAudioBufferListPointer
    ) {
        let recordedFrames = UnsafeBufferPointer(frames)
        var peak: Float = 0
        var clippedSamples = 0
        for frame in 0..<frameCount {
            let sample = Float(bank.pointee.nextSample(from: recordedFrames, in: settings)) * amplitude
            peak = max(peak, abs(sample))
            clippedSamples += abs(sample) > 1 ? 1 : 0
            write(sample, atFrame: frame, into: buffers)
        }
        health.recordOutput(peak: peak, clippedSamples: clippedSamples)
    }

    private func write(_ sample: Float, atFrame frame: Int, into buffers: UnsafeMutableAudioBufferListPointer) {
        for buffer in buffers {
            UnsafeMutableBufferPointer<Float>(buffer)[frame] = sample
        }
    }
}

// MARK: - PlayableTone

private typealias PlayableTone = (tone: SoundingTone, recorded: RecordedNote)

// MARK: - ReedCommand

private enum ReedCommand {
    case sound(crossfadeSeconds: Double, everyReedSpeaksAgain: Bool)
    case ringDown
    case damp(seconds: Double)
}

// MARK: - ReedCommandQueue

private final class ReedCommandQueue: @unchecked Sendable {
    static let capacity = 256
    static let mostTonesPerCommand = 10

    private let commands: UnsafeMutablePointer<ReedCommand>
    private let toneCounts: UnsafeMutablePointer<Int>
    private let tones: UnsafeMutablePointer<PlayableTone>
    private let commandsWritten = Atomic<Int>(0)
    private let commandsRead = Atomic<Int>(0)

    // MARK: - Public

    init() {
        commands = .allocate(capacity: Self.capacity)
        toneCounts = .allocate(capacity: Self.capacity)
        tones = .allocate(capacity: Self.capacity * Self.mostTonesPerCommand)
    }

    deinit {
        commands.deallocate()
        toneCounts.deallocate()
        tones.deallocate()
    }

    func push(_ command: ReedCommand, tones tonesToSend: [PlayableTone]) -> Bool {
        let nextCommandToWrite = commandsWritten.load(ordering: .relaxed)
        guard nextCommandToWrite - commandsRead.load(ordering: .acquiring) < Self.capacity else { return false }

        let slotOfTheCommand = nextCommandToWrite % Self.capacity
        (commands + slotOfTheCommand).initialize(to: command)
        (toneCounts + slotOfTheCommand).initialize(to: tonesToSend.count)
        _ = UnsafeMutableBufferPointer(start: tonesOf(slotOfTheCommand), count: tonesToSend.count)
            .initialize(fromContentsOf: tonesToSend)
        commandsWritten.store(nextCommandToWrite + 1, ordering: .releasing)
        return true
    }

    func drain(_ apply: (ReedCommand, UnsafeBufferPointer<PlayableTone>) -> Void) {
        let firstUnreadCommand = commandsRead.load(ordering: .relaxed)
        let commandsWrittenSoFar = commandsWritten.load(ordering: .acquiring)
        for commandNumber in firstUnreadCommand..<commandsWrittenSoFar {
            let slotOfTheCommand = commandNumber % Self.capacity
            apply(
                commands[slotOfTheCommand],
                UnsafeBufferPointer(start: tonesOf(slotOfTheCommand), count: toneCounts[slotOfTheCommand])
            )
        }
        commandsRead.store(commandsWrittenSoFar, ordering: .releasing)
    }

    // MARK: - Private

    private func tonesOf(_ slot: Int) -> UnsafeMutablePointer<PlayableTone> {
        tones + slot * Self.mostTonesPerCommand
    }
}

// MARK: - RenderSettings

private struct RenderSettings {
    let sampleRate: Double
    let ramp: GainRamp
    let breathGain: Double
    let vibrato: VibratoSettings
    let cupCoefficient: Double
}

// MARK: - VibratoSettings

private struct VibratoSettings {
    let hertz: Double
    let depth: Double
}

// MARK: - GainRamp

private struct GainRamp {
    let rising: Double
    let falling: Double
}

// MARK: - Vibrato

private struct Vibrato {
    let pitchRatio: Double
    let gain: Double
}

// MARK: - VoiceBank

private struct VoiceBank {
    static let mostVoices = 32
    static let reedsOneMouthCovers = 4.0
    static let ringDownCycles = 30.0
    static let vibratoHertz = 5.5
    static let vibratoPitchAtFullDepth = 0.015
    static let vibratoDipAtFullDepth = 0.25
    static let vibratoDriftHertz = 0.23
    static let vibratoRateDrift = 0.08
    static let vibratoDepthDrift = 0.2

    let voices = UnsafeMutablePointer<Voice>.allocate(capacity: Self.mostVoices)
    var voiceCount = 0
    var breathGain = 0.0
    var lfoPhase = 0.0
    var crossfadeSeconds = 0.02
    var cupped = 0.0
    var driftPhase = 0.0
    var isRingingDown = false
    var stolenVoices = 0

    // MARK: - Public

    var isSilent: Bool {
        voiceCount == 0
    }

    func releaseTheVoices() {
        voices.deinitialize(count: voiceCount)
        voices.deallocate()
    }

    mutating func apply(_ command: ReedCommand, tones: UnsafeBufferPointer<PlayableTone>) {
        switch command {
        case let .sound(seconds, again):
            sound(tones, over: seconds, everyReedSpeaksAgain: again)
        case .ringDown:
            ringDown()
        case let .damp(seconds):
            damp(over: seconds)
        }
    }

    mutating func prepareRingDown(sampleRate: Double) {
        guard isRingingDown else { return }

        for index in 0..<voiceCount {
            voices[index].ringDown(overCycles: Self.ringDownCycles, sampleRate: sampleRate)
        }
    }

    mutating func bend(by fraction: Double) {
        for index in 0..<voiceCount {
            voices[index].bend(by: fraction)
        }
    }

    mutating func driftedVibrato(depth: Double, overFrames frameCount: Int, sampleRate: Double) -> VibratoSettings {
        driftPhase = advanced(driftPhase, byCycles: Self.vibratoDriftHertz * Double(frameCount) / sampleRate)
        let wandering = sin(driftPhase)
        return VibratoSettings(
            hertz: Self.vibratoHertz * (1 + Self.vibratoRateDrift * wandering),
            depth: depth * (1 - Self.vibratoDepthDrift * (1 + wandering) / 2)
        )
    }

    mutating func nextSample(from frames: UnsafeBufferPointer<Float>, in settings: RenderSettings) -> Double {
        breathGain = ramped(breathGain, toward: settings.breathGain, by: settings.ramp)
        let gainPerReed = breathGain / airSpreadAcrossTheReeds
        let vibrato = nextVibrato(sampleRate: settings.sampleRate, through: settings.vibrato)

        var summedVoices = 0.0
        for index in 0..<voiceCount {
            summedVoices += voices[index].nextSample(
                from: frames,
                sampleRate: settings.sampleRate,
                ramp: settings.ramp,
                pitchRatio: vibrato.pitchRatio
            )
        }
        cupped += (summedVoices * gainPerReed * vibrato.gain - cupped) * settings.cupCoefficient
        return cupped
    }

    mutating func takeStolenVoices() -> Int {
        defer { stolenVoices = 0 }

        return stolenVoices
    }

    mutating func forgetSilentVoices() {
        var voicesStillSounding = 0
        for index in 0..<voiceCount where !voices[index].isSilent {
            voices[voicesStillSounding] = voices[index]
            voicesStillSounding += 1
        }
        voiceCount = voicesStillSounding
    }

    // MARK: - Private

    private var airSpreadAcrossTheReeds: Double {
        max(1, soundingGain / Self.reedsOneMouthCovers)
    }

    private var soundingGain: Double {
        var gainOfEveryVoice = 0.0
        for index in 0..<voiceCount {
            gainOfEveryVoice += voices[index].gain
        }
        return gainOfEveryVoice
    }

    private var quietestVoice: Int {
        var quietestSoFar = 0
        for index in 1..<max(1, voiceCount) where voices[index].gain < voices[quietestSoFar].gain {
            quietestSoFar = index
        }
        return quietestSoFar
    }

    private mutating func sound(
        _ playable: UnsafeBufferPointer<PlayableTone>,
        over seconds: Double,
        everyReedSpeaksAgain: Bool
    ) {
        crossfadeSeconds = seconds
        isRingingDown = false
        for index in 0..<voiceCount where everyReedSpeaksAgain || !isStillWanted(voices[index], in: playable) {
            voices[index].targetGain = 0
        }
        for wanted in playable where !isRising(atHertz: wanted.tone.hertz) {
            add(wanted)
        }
    }

    private mutating func ringDown() {
        isRingingDown = true
        for index in 0..<voiceCount {
            voices[index].targetGain = 0
        }
    }

    private mutating func damp(over seconds: Double) {
        isRingingDown = false
        crossfadeSeconds = seconds
        for index in 0..<voiceCount {
            voices[index].targetGain = 0
        }
    }

    private func isStillWanted(_ voice: Voice, in playable: UnsafeBufferPointer<PlayableTone>) -> Bool {
        voice.targetGain > 0 && playable.contains { $0.tone.hertz == voice.hertz }
    }

    private func isRising(atHertz hertz: Double) -> Bool {
        for index in 0..<voiceCount where voices[index].hertz == hertz && voices[index].targetGain > 0 {
            return true
        }
        return false
    }

    private mutating func add(_ wanted: PlayableTone) {
        let voice = Voice(wanted.tone, playing: wanted.recorded)
        guard voiceCount < Self.mostVoices else {
            voices[quietestVoice] = voice
            stolenVoices += 1
            return
        }

        (voices + voiceCount).initialize(to: voice)
        voiceCount += 1
    }

    private mutating func nextVibrato(sampleRate: Double, through vibrato: VibratoSettings) -> Vibrato {
        lfoPhase = advanced(lfoPhase, byCycles: vibrato.hertz / sampleRate)
        let swing = sin(lfoPhase)
        return Vibrato(
            pitchRatio: 1 + vibrato.depth * Self.vibratoPitchAtFullDepth * swing,
            gain: 1 - vibrato.depth * Self.vibratoDipAtFullDepth * (1 + swing) / 2
        )
    }
}

// MARK: - Voice

private struct Voice {
    static let inaudibleGain = 0.001

    let hertz: Double
    let bendableSemitones: Double
    let recorded: RecordedNote

    var position = 0.0
    var gain = 0.0
    var targetGain = 1.0
    var bendRatio = 1.0
    var decayPerSample = 0.0

    init(_ tone: SoundingTone, playing recorded: RecordedNote) {
        hertz = tone.hertz
        bendableSemitones = tone.bendableSemitones
        self.recorded = recorded
    }

    var isSilent: Bool {
        gain <= Self.inaudibleGain && targetGain <= 0
    }

    mutating func ringDown(overCycles cycles: Double, sampleRate: Double) {
        decayPerSample = pow(Self.inaudibleGain, hertz / (cycles * sampleRate))
    }

    mutating func bend(by fraction: Double) {
        bendRatio = pow(2, -bendableSemitones * fraction / 12)
    }

    mutating func nextSample(
        from frames: UnsafeBufferPointer<Float>,
        sampleRate: Double,
        ramp: GainRamp,
        pitchRatio: Double
    ) -> Double {
        let sampleAtItsGain = Double(interpolated(from: frames)) * gain
        position += positionIncrement(sampleRate: sampleRate, pitchRatio: pitchRatio)
        wrapIntoTheLoop()
        advanceGain(by: ramp)
        return sampleAtItsGain
    }

    // MARK: - Private

    private mutating func advanceGain(by ramp: GainRamp) {
        guard decayPerSample > 0, targetGain <= 0 else {
            gain = ramped(gain, toward: targetGain, by: ramp)
            return
        }

        gain *= decayPerSample
    }

    private func interpolated(from frames: UnsafeBufferPointer<Float>) -> Float {
        let frame = Int(position)
        let here = frames[recorded.start + frame]
        let next = frames[recorded.start + (frame + 1 < recorded.loopEnd ? frame + 1 : recorded.loopStart)]
        return here + (next - here) * Float(position - Double(frame))
    }

    private func positionIncrement(sampleRate: Double, pitchRatio: Double) -> Double {
        hertz * bendRatio * pitchRatio / recorded.rootHertz * recorded.sampleRate / sampleRate
    }

    private mutating func wrapIntoTheLoop() {
        let length = Double(recorded.loopEnd - recorded.loopStart)
        while position >= Double(recorded.loopEnd) {
            position -= length
        }
    }
}

// MARK: - Ramping

private let radiansPerCycle = 2 * Double.pi

private func advanced(_ phase: Double, byCycles cycles: Double) -> Double {
    (phase + radiansPerCycle * cycles).truncatingRemainder(dividingBy: radiansPerCycle)
}

private func ramped(_ gain: Double, toward target: Double, by ramp: GainRamp) -> Double {
    gain < target ? min(target, gain + ramp.rising) : max(target, gain - ramp.falling)
}
