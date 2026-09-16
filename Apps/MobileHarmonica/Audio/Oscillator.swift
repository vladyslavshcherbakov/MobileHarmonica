import AVFoundation
import os

final class Oscillator {
    private static let crossfadeSeconds = 0.02

    private let voices = OSAllocatedUnfairLock(initialState: VoiceSet())

    // MARK: - Public

    func sound(atHertz hertz: Double) {
        voices.withLock { $0.sound(atHertz: hertz) }
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

        fill(frameCount: frameCount, sampleRate: sampleRate, amplitude: amplitude, into: buffers, from: &rendering)
        keep(rendering)
    }

    // MARK: - Private

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
        from rendering: inout VoiceSet
    ) {
        let gainStep = 1 / (Self.crossfadeSeconds * sampleRate)
        for frame in 0..<frameCount {
            let value = rendering.nextSample(sampleRate: sampleRate, gainStep: gainStep)
            write(Float(value) * amplitude, atFrame: frame, into: buffers)
        }
    }

    private func keep(_ rendering: VoiceSet) {
        voices.withLock { current in
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

// MARK: - VoiceSet

private struct VoiceSet {
    var sounding: Voice?
    var fading: Voice?
    var changeCount = 0

    var isSilent: Bool {
        sounding == nil && fading == nil
    }

    mutating func sound(atHertz hertz: Double) {
        release()
        sounding = Voice(hertz: hertz, phase: 0, gain: 0, targetGain: 1)
        changeCount += 1
    }

    mutating func silence() {
        release()
        changeCount += 1
    }

    mutating func nextSample(sampleRate: Double, gainStep: Double) -> Double {
        Self.advance(&sounding, sampleRate: sampleRate, gainStep: gainStep)
            + Self.advance(&fading, sampleRate: sampleRate, gainStep: gainStep)
    }

    private static func advance(_ voice: inout Voice?, sampleRate: Double, gainStep: Double) -> Double {
        guard var playing = voice else { return 0 }

        let value = playing.nextSample(sampleRate: sampleRate, gainStep: gainStep)
        voice = playing.isSilent ? nil : playing
        return value
    }

    private mutating func release() {
        guard var releasing = sounding else { return }

        releasing.targetGain = 0
        fading = releasing
        sounding = nil
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
