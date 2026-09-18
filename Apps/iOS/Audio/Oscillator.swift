import AVFoundation
import os

final class Oscillator {
    private static let reedSpeaksInSeconds = 0.005
    private static let reedStopsInSeconds = 0.02
    private static let openCupHertz = 2800.0
    private static let closedCupHertz = 600.0
    private static let cupResonance = 4.0

    private let samples: SampleBank
    private let voices = OSAllocatedUnfairLock(initialState: VoiceBank())
    private let requestedBreathGain = OSAllocatedUnfairLock(initialState: 0.0)
    private let requestedBend = OSAllocatedUnfairLock(initialState: 0.0)
    private let requestedVibrato = OSAllocatedUnfairLock(initialState: 0.0)
    private let requestedCup = OSAllocatedUnfairLock(initialState: 0.0)

    // MARK: - Public

    init(samples: SampleBank) {
        self.samples = samples
    }

    func sound(_ tones: [SoundingTone], over crossfadeSeconds: Double, everyReedSpeaksAgain: Bool) {
        let playable = recorded(tones)
        voices.withLock {
            $0.sound(playable, over: crossfadeSeconds, everyReedSpeaksAgain: everyReedSpeaksAgain)
        }
    }

    func changeBreathGain(to gain: Double) {
        requestedBreathGain.withLock { $0 = gain }
    }

    func changeBend(to fraction: Double) {
        requestedBend.withLock { $0 = fraction }
    }

    func changeVibrato(to fraction: Double) {
        requestedVibrato.withLock { $0 = fraction }
    }

    func cupHands(to fraction: Double) {
        requestedCup.withLock { $0 = fraction }
    }

    func ringDown() {
        voices.withLock { $0.ringDown() }
    }

    func damp() {
        voices.withLock { $0.damp(over: Self.reedStopsInSeconds) }
    }

    func render(
        frameCount: Int,
        sampleRate: Double,
        amplitude: Float,
        into buffers: UnsafeMutableAudioBufferListPointer
    ) {
        var rendering = voices.withLock { $0 }
        guard !rendering.isSilent else {
            fillWithSilence(frameCount: frameCount, into: buffers)
            return
        }

        rendering.bend(by: requestedBend.withLock { $0 })
        rendering.prepareRingDown(sampleRate: sampleRate)
        let vibrato = rendering.driftedVibrato(
            depth: requestedVibrato.withLock { $0 },
            overFrames: frameCount,
            sampleRate: sampleRate
        )
        fill(
            frameCount: frameCount,
            amplitude: amplitude,
            settings: RenderSettings(
                sampleRate: sampleRate,
                ramp: Self.gainRamp(crossfadeSeconds: rendering.crossfadeSeconds, sampleRate: sampleRate),
                breathGain: requestedBreathGain.withLock { $0 },
                vibrato: vibrato,
                cup: Self.cupSettings(closed: requestedCup.withLock { $0 }, sampleRate: sampleRate)
            ),
            into: buffers,
            from: &rendering
        )
        keepProgress(of: rendering)
    }

    // MARK: - Private

    private func recorded(_ tones: [SoundingTone]) -> [PlayableTone] {
        tones.compactMap { tone in
            samples.nearest(to: tone.hertz).map { (tone: tone, recorded: $0) }
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
        into buffers: UnsafeMutableAudioBufferListPointer,
        from rendering: inout VoiceBank
    ) {
        samples.frames.withUnsafeBufferPointer { frames in
            for frame in 0..<frameCount {
                let value = rendering.nextSample(from: frames, in: settings)
                write(Float(value) * amplitude, atFrame: frame, into: buffers)
            }
        }
    }

    private static func cupSettings(closed: Double, sampleRate: Double) -> CupSettings {
        let hertz = openCupHertz * pow(closedCupHertz / openCupHertz, closed)
        return CupSettings(
            closed: closed,
            ringing: 2 * sin(Double.pi * hertz / sampleRate),
            damping: 1 / cupResonance
        )
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

    /// The bank can be re-sounded while the buffer is being filled, so the rendered copy is
    /// not written back whole. What it carries back is a buffer's worth of progress, applied
    /// to whatever the bank asks for by the time the buffer is done, so neither a note started
    /// mid-buffer nor the position the buffer just advanced is lost.
    private func keepProgress(of rendering: VoiceBank) {
        voices.withLock { $0.absorbProgress(of: rendering) }
    }

    private func write(_ sample: Float, atFrame frame: Int, into buffers: UnsafeMutableAudioBufferListPointer) {
        for buffer in buffers {
            UnsafeMutableBufferPointer<Float>(buffer)[frame] = sample
        }
    }
}

// MARK: - SoundingTone

struct SoundingTone: Equatable {
    let hertz: Double
    let bendableSemitones: Double
}

// MARK: - PlayableTone

private typealias PlayableTone = (tone: SoundingTone, recorded: RecordedNote)

// MARK: - RenderSettings

private struct RenderSettings {
    let sampleRate: Double
    let ramp: GainRamp
    let breathGain: Double
    let vibrato: VibratoSettings
    let cup: CupSettings
}

// MARK: - VibratoSettings

private struct VibratoSettings {
    let hertz: Double
    let depth: Double
}

// MARK: - CupSettings

private struct CupSettings {
    let closed: Double
    let ringing: Double
    let damping: Double
}

// MARK: - CupFilter

private struct CupFilter {
    var low = 0.0
    var band = 0.0

    mutating func next(_ sample: Double, through cup: CupSettings) -> Double {
        low += cup.ringing * band
        band += cup.ringing * (sample - low - cup.damping * band)
        return sample + (low * cup.damping - sample) * cup.closed
    }
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
    static let reedsOneMouthCovers = 4.0
    static let ringDownCycles = 30.0
    static let vibratoHertz = 5.5
    static let vibratoPitchAtFullDepth = 0.015
    static let vibratoDipAtFullDepth = 0.25
    static let vibratoDriftHertz = 0.23
    static let vibratoRateDrift = 0.08
    static let vibratoDepthDrift = 0.2

    var voices: [Voice] = []
    var breathGain = 0.0
    var lfoPhase = 0.0
    var crossfadeSeconds = 0.02
    var voicesEverSounded = 0
    var cup = CupFilter()
    var driftPhase = 0.0
    var ringingDown = false

    // MARK: - Public

    var isSilent: Bool {
        voices.isEmpty
    }

    mutating func sound(_ playable: [PlayableTone], over seconds: Double, everyReedSpeaksAgain: Bool) {
        crossfadeSeconds = seconds
        ringingDown = false
        for index in voices.indices where everyReedSpeaksAgain || !isStillWanted(voices[index], in: playable) {
            voices[index].targetGain = 0
        }
        for wanted in playable where !isRising(atHertz: wanted.tone.hertz) {
            add(wanted)
        }
    }

    mutating func ringDown() {
        ringingDown = true
        for index in voices.indices {
            voices[index].targetGain = 0
        }
    }

    mutating func damp(over seconds: Double) {
        ringingDown = false
        crossfadeSeconds = seconds
        for index in voices.indices {
            voices[index].targetGain = 0
        }
    }

    mutating func prepareRingDown(sampleRate: Double) {
        guard ringingDown else { return }

        for index in voices.indices {
            voices[index].ringDown(overCycles: Self.ringDownCycles, sampleRate: sampleRate)
        }
    }

    mutating func bend(by fraction: Double) {
        for index in voices.indices {
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
        let scale = breathGain / airSpreadAcrossTheReeds
        let vibrato = nextVibrato(sampleRate: settings.sampleRate, through: settings.vibrato)

        var mixed = 0.0
        for index in voices.indices {
            mixed += voices[index].nextSample(
                from: frames,
                sampleRate: settings.sampleRate,
                ramp: settings.ramp,
                pitchRatio: vibrato.pitchRatio
            )
        }
        return cup.next(mixed * scale * vibrato.gain, through: settings.cup)
    }

    mutating func absorbProgress(of rendered: VoiceBank) {
        breathGain = rendered.breathGain
        lfoPhase = rendered.lfoPhase
        driftPhase = rendered.driftPhase
        cup = rendered.cup
        for index in voices.indices {
            voices[index].absorbProgress(of: rendered.voice(numbered: voices[index].number))
        }
        voices.removeAll { $0.isSilent }
    }

    // MARK: - Private

    private var airSpreadAcrossTheReeds: Double {
        max(1, soundingGain / Self.reedsOneMouthCovers)
    }

    private var soundingGain: Double {
        voices.reduce(0) { $0 + $1.gain }
    }

    private func voice(numbered number: Int) -> Voice? {
        voices.first { $0.number == number }
    }

    private func isStillWanted(_ voice: Voice, in playable: [PlayableTone]) -> Bool {
        voice.targetGain > 0 && playable.contains { $0.tone.hertz == voice.hertz }
    }

    private mutating func add(_ wanted: PlayableTone) {
        voicesEverSounded += 1
        voices.append(Voice(wanted.tone, playing: wanted.recorded, number: voicesEverSounded))
    }

    private mutating func nextVibrato(sampleRate: Double, through vibrato: VibratoSettings) -> Vibrato {
        lfoPhase = advanced(lfoPhase, byCycles: vibrato.hertz / sampleRate)
        let swing = sin(lfoPhase)
        return Vibrato(
            pitchRatio: 1 + vibrato.depth * Self.vibratoPitchAtFullDepth * swing,
            gain: 1 - vibrato.depth * Self.vibratoDipAtFullDepth * (1 + swing) / 2
        )
    }

    private func isRising(atHertz hertz: Double) -> Bool {
        voices.contains { $0.hertz == hertz && $0.targetGain > 0 }
    }
}

// MARK: - Voice

private struct Voice {
    static let inaudibleGain = 0.001

    let number: Int
    let hertz: Double
    let bendableSemitones: Double
    let recorded: RecordedNote

    var position = 0.0
    var gain = 0.0
    var targetGain = 1.0
    var bendRatio = 1.0
    var decayPerSample = 0.0

    init(_ tone: SoundingTone, playing recorded: RecordedNote, number: Int) {
        self.number = number
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

    /// A voice the render pass did not hold has either just been added to the bank or has
    /// finished fading out there, and both belong at the start of the recording.
    mutating func absorbProgress(of rendered: Voice?) {
        position = rendered?.position ?? 0
        gain = rendered?.gain ?? 0
    }

    mutating func nextSample(
        from frames: UnsafeBufferPointer<Float>,
        sampleRate: Double,
        ramp: GainRamp,
        pitchRatio: Double
    ) -> Double {
        let value = Double(interpolated(from: frames)) * gain
        position += positionIncrement(sampleRate: sampleRate, pitchRatio: pitchRatio)
        wrapIntoTheLoop()
        advanceGain(by: ramp)
        return value
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
