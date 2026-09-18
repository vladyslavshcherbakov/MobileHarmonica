import AVFoundation
import os

final class Oscillator {
    private static let reedSpeaksInSeconds = 0.005

    private let samples: SampleBank
    private let voices = OSAllocatedUnfairLock(initialState: VoiceBank())
    private let requestedBreathGain = OSAllocatedUnfairLock(initialState: 0.0)
    private let requestedBend = OSAllocatedUnfairLock(initialState: 0.0)
    private let requestedVibrato = OSAllocatedUnfairLock(initialState: 0.0)

    // MARK: - Public

    init(samples: SampleBank) {
        self.samples = samples
    }

    func sound(_ tones: [SoundingTone], over crossfadeSeconds: Double) {
        let playable = recorded(tones)
        voices.withLock { $0.sound(playable, over: crossfadeSeconds) }
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

    func silence() {
        voices.withLock { $0.silence() }
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
        fill(
            frameCount: frameCount,
            sampleRate: sampleRate,
            amplitude: amplitude,
            breathGain: requestedBreathGain.withLock { $0 },
            vibrato: requestedVibrato.withLock { $0 },
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
        sampleRate: Double,
        amplitude: Float,
        breathGain: Double,
        vibrato: Double,
        into buffers: UnsafeMutableAudioBufferListPointer,
        from rendering: inout VoiceBank
    ) {
        let ramp = Self.gainRamp(crossfadeSeconds: rendering.crossfadeSeconds, sampleRate: sampleRate)
        samples.frames.withUnsafeBufferPointer { frames in
            for frame in 0..<frameCount {
                let value = rendering.nextSample(
                    from: frames,
                    sampleRate: sampleRate,
                    ramp: ramp,
                    targetBreathGain: breathGain,
                    vibrato: vibrato
                )
                write(Float(value) * amplitude, atFrame: frame, into: buffers)
            }
        }
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
    static let vibratoHertz = 5.5
    static let vibratoPitchAtFullDepth = 0.015
    static let vibratoDipAtFullDepth = 0.25

    var voices: [Voice] = []
    var breathGain = 0.0
    var lfoPhase = 0.0
    var crossfadeSeconds = 0.02

    // MARK: - Public

    var isSilent: Bool {
        voices.isEmpty
    }

    mutating func sound(_ playable: [PlayableTone], over seconds: Double) {
        crossfadeSeconds = seconds
        for index in voices.indices {
            voices[index].targetGain = playable.contains { $0.tone.hertz == voices[index].hertz } ? 1 : 0
        }
        for wanted in playable where !isRising(atHertz: wanted.tone.hertz) {
            voices.append(Voice(wanted.tone, playing: wanted.recorded))
        }
    }

    mutating func silence() {
        for index in voices.indices {
            voices[index].targetGain = 0
        }
    }

    mutating func bend(by fraction: Double) {
        for index in voices.indices {
            voices[index].bend(by: fraction)
        }
    }

    mutating func nextSample(
        from frames: UnsafeBufferPointer<Float>,
        sampleRate: Double,
        ramp: GainRamp,
        targetBreathGain: Double,
        vibrato depth: Double
    ) -> Double {
        breathGain = ramped(breathGain, toward: targetBreathGain, by: ramp)
        let scale = breathGain / airSpreadAcrossTheReeds
        let vibrato = nextVibrato(sampleRate: sampleRate, depth: depth)

        var mixed = 0.0
        for index in voices.indices {
            mixed += voices[index].nextSample(
                from: frames,
                sampleRate: sampleRate,
                ramp: ramp,
                pitchRatio: vibrato.pitchRatio
            )
        }
        return mixed * scale * vibrato.gain
    }

    mutating func absorbProgress(of rendered: VoiceBank) {
        breathGain = rendered.breathGain
        lfoPhase = rendered.lfoPhase
        for index in voices.indices {
            voices[index].absorbProgress(of: rendered.voice(atHertz: voices[index].hertz))
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

    private func voice(atHertz hertz: Double) -> Voice? {
        voices.first { $0.hertz == hertz }
    }

    private mutating func nextVibrato(sampleRate: Double, depth: Double) -> Vibrato {
        lfoPhase = (lfoPhase + radiansPerCycle * Self.vibratoHertz / sampleRate)
            .truncatingRemainder(dividingBy: radiansPerCycle)
        let swing = sin(lfoPhase)
        return Vibrato(
            pitchRatio: 1 + depth * Self.vibratoPitchAtFullDepth * swing,
            gain: 1 - depth * Self.vibratoDipAtFullDepth * (1 + swing) / 2
        )
    }

    private func isRising(atHertz hertz: Double) -> Bool {
        voices.contains { $0.hertz == hertz && $0.targetGain > 0 }
    }
}

// MARK: - Voice

private struct Voice {
    let hertz: Double
    let bendableSemitones: Double
    let recorded: RecordedNote

    var position = 0.0
    var gain = 0.0
    var targetGain = 1.0
    var bendRatio = 1.0

    init(_ tone: SoundingTone, playing recorded: RecordedNote) {
        hertz = tone.hertz
        bendableSemitones = tone.bendableSemitones
        self.recorded = recorded
    }

    var isSilent: Bool {
        gain <= 0 && targetGain <= 0
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
        gain = ramped(gain, toward: targetGain, by: ramp)
        return value
    }

    // MARK: - Private

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

private func ramped(_ gain: Double, toward target: Double, by ramp: GainRamp) -> Double {
    gain < target ? min(target, gain + ramp.rising) : max(target, gain - ramp.falling)
}
