import AVFoundation
import os

final class Oscillator {
    private static let crossfadeSeconds = 0.02

    private let bank = OSAllocatedUnfairLock(initialState: VoiceBank())
    private let requestedBreathGain = OSAllocatedUnfairLock(initialState: 0.0)
    private let requestedBend = OSAllocatedUnfairLock(initialState: 0.0)
    private let requestedVibrato = OSAllocatedUnfairLock(initialState: 0.0)

    // MARK: - Public

    func sound(_ tones: [SoundingTone]) {
        bank.withLock { $0.sound(tones) }
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
        bank.withLock { $0.silence() }
    }

    func render(
        frameCount: Int,
        sampleRate: Double,
        amplitude: Float,
        into buffers: UnsafeMutableAudioBufferListPointer
    ) {
        var rendering = bank.withLock { $0 }
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

    private static func gainStep(sampleRate: Double) -> Double {
        1 / (crossfadeSeconds * sampleRate)
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
        let gainStep = Self.gainStep(sampleRate: sampleRate)
        for frame in 0..<frameCount {
            let value = rendering.nextSample(
                sampleRate: sampleRate,
                gainStep: gainStep,
                targetBreathGain: breathGain,
                vibrato: vibrato
            )
            write(Float(value) * amplitude, atFrame: frame, into: buffers)
        }
    }

    /// The bank can be re-sounded while the buffer is being filled, so the rendered copy is
    /// not written back whole. What it carries back is a buffer's worth of progress, applied
    /// to whatever the bank asks for by the time the buffer is done, so neither a note started
    /// mid-buffer nor the phase the buffer just advanced is lost.
    private func keepProgress(of rendering: VoiceBank) {
        bank.withLock { $0.absorbProgress(of: rendering) }
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

// MARK: - VoiceBank

private struct VoiceBank {
    static let vibratoHertz = 5.5
    static let vibratoRatioAtFullDepth = 0.03

    var voices: [Voice] = []
    var breathGain = 0.0
    var lfoPhase = 0.0

    // MARK: - Public

    var isSilent: Bool {
        voices.isEmpty
    }

    mutating func sound(_ tones: [SoundingTone]) {
        for index in voices.indices {
            voices[index].targetGain = tones.contains { $0.hertz == voices[index].hertz } ? 1 : 0
        }
        for tone in tones where !isRising(atHertz: tone.hertz) {
            voices.append(Voice(tone))
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
        sampleRate: Double,
        gainStep: Double,
        targetBreathGain: Double,
        vibrato: Double
    ) -> Double {
        breathGain = ramp(breathGain, toward: targetBreathGain, by: gainStep)
        let scale = breathGain / max(1, soundingGain)
        let vibratoRatio = nextVibratoRatio(sampleRate: sampleRate, depth: vibrato)

        var mixed = 0.0
        for index in voices.indices {
            mixed += voices[index].nextSample(
                sampleRate: sampleRate,
                gainStep: gainStep,
                vibratoRatio: vibratoRatio
            )
        }
        return mixed * scale
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

    private var soundingGain: Double {
        voices.reduce(0) { $0 + $1.gain }
    }

    private func voice(atHertz hertz: Double) -> Voice? {
        voices.first { $0.hertz == hertz }
    }

    private mutating func nextVibratoRatio(sampleRate: Double, depth: Double) -> Double {
        lfoPhase = (lfoPhase + radiansPerCycle * Self.vibratoHertz / sampleRate)
            .truncatingRemainder(dividingBy: radiansPerCycle)
        return 1 + depth * Self.vibratoRatioAtFullDepth * sin(lfoPhase)
    }

    private func isRising(atHertz hertz: Double) -> Bool {
        voices.contains { $0.hertz == hertz && $0.targetGain > 0 }
    }
}

// MARK: - Voice

private struct Voice {
    let hertz: Double
    let bendableSemitones: Double

    var phase = 0.0
    var gain = 0.0
    var targetGain = 1.0
    var bendRatio = 1.0

    init(_ tone: SoundingTone) {
        hertz = tone.hertz
        bendableSemitones = tone.bendableSemitones
    }

    var isSilent: Bool {
        gain <= 0 && targetGain <= 0
    }

    mutating func bend(by fraction: Double) {
        bendRatio = pow(2, -bendableSemitones * fraction / 12)
    }

    /// A voice the render pass did not hold has either just been added to the bank or has
    /// finished fading out there, and both belong at the start of a cycle.
    mutating func absorbProgress(of rendered: Voice?) {
        phase = rendered?.phase ?? 0
        gain = rendered?.gain ?? 0
    }

    mutating func nextSample(sampleRate: Double, gainStep: Double, vibratoRatio: Double) -> Double {
        let value = sin(phase) * gain
        phase = (phase + phaseIncrement(sampleRate: sampleRate, vibratoRatio: vibratoRatio))
            .truncatingRemainder(dividingBy: radiansPerCycle)
        gain = ramp(gain, toward: targetGain, by: gainStep)
        return value
    }

    private func phaseIncrement(sampleRate: Double, vibratoRatio: Double) -> Double {
        radiansPerCycle * hertz * bendRatio * vibratoRatio / sampleRate
    }
}

// MARK: - Ramping

private let radiansPerCycle = 2 * Double.pi

private func ramp(_ gain: Double, toward target: Double, by step: Double) -> Double {
    gain < target ? min(target, gain + step) : max(target, gain - step)
}
