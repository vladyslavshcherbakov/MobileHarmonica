import AVFoundation
import os

final class Oscillator {
    private static let crossfadeSeconds = 0.02

    private let bank = OSAllocatedUnfairLock(initialState: VoiceBank())

    // MARK: - Public

    func sound(atHertz hertzValues: [Double]) {
        bank.withLock { $0.sound(atHertz: hertzValues) }
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

        fill(frameCount: frameCount, sampleRate: sampleRate, amplitude: amplitude, into: buffers, from: &rendering)
        rendering.dropSilentVoices()
        keep(rendering)
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
        into buffers: UnsafeMutableAudioBufferListPointer,
        from rendering: inout VoiceBank
    ) {
        let gainStep = Self.gainStep(sampleRate: sampleRate)
        for frame in 0..<frameCount {
            let value = rendering.nextSample(sampleRate: sampleRate, gainStep: gainStep)
            write(Float(value) * amplitude, atFrame: frame, into: buffers)
        }
    }

    private func keep(_ rendering: VoiceBank) {
        bank.withLock { current in
            guard current.changeCount == rendering.changeCount else { return }

            current = rendering
        }
    }

    private func write(_ sample: Float, atFrame frame: Int, into buffers: UnsafeMutableAudioBufferListPointer) {
        for buffer in buffers {
            UnsafeMutableBufferPointer<Float>(buffer)[frame] = sample
        }
    }
}

// MARK: - VoiceBank

private struct VoiceBank {
    var voices: [Voice] = []
    var changeCount = 0

    var isSilent: Bool {
        voices.isEmpty
    }

    mutating func sound(atHertz hertzValues: [Double]) {
        for index in voices.indices {
            voices[index].targetGain = hertzValues.contains(voices[index].hertz) ? 1 : 0
        }
        for hertz in hertzValues where !isRising(atHertz: hertz) {
            voices.append(Voice(hertz: hertz, phase: 0, gain: 0, targetGain: 1))
        }
        changeCount += 1
    }

    mutating func silence() {
        for index in voices.indices {
            voices[index].targetGain = 0
        }
        changeCount += 1
    }

    mutating func nextSample(sampleRate: Double, gainStep: Double) -> Double {
        let scale = 1 / max(1, soundingGain)
        var mixed = 0.0
        for index in voices.indices {
            mixed += voices[index].nextSample(sampleRate: sampleRate, gainStep: gainStep)
        }
        return mixed * scale
    }

    mutating func dropSilentVoices() {
        voices.removeAll { $0.isSilent }
    }

    private var soundingGain: Double {
        voices.reduce(0) { $0 + $1.gain }
    }

    private func isRising(atHertz hertz: Double) -> Bool {
        voices.contains { $0.hertz == hertz && $0.targetGain > 0 }
    }
}

// MARK: - Voice

private struct Voice {
    private static let radiansPerCycle = 2 * Double.pi

    var hertz: Double
    var phase: Double
    var gain: Double
    var targetGain: Double

    var isSilent: Bool {
        gain <= 0 && targetGain <= 0
    }

    mutating func nextSample(sampleRate: Double, gainStep: Double) -> Double {
        let value = sin(phase) * gain
        phase = (phase + phaseIncrement(sampleRate: sampleRate))
            .truncatingRemainder(dividingBy: Self.radiansPerCycle)
        gain = nextGain(step: gainStep)
        return value
    }

    private func phaseIncrement(sampleRate: Double) -> Double {
        Self.radiansPerCycle * hertz / sampleRate
    }

    private func nextGain(step: Double) -> Double {
        gain < targetGain ? min(targetGain, gain + step) : max(targetGain, gain - step)
    }
}
