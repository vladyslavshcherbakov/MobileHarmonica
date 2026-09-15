import AVFoundation
import os

final class Oscillator {
    private static let radiansPerCycle = 2 * Double.pi

    private let tone = OSAllocatedUnfairLock<Tone?>(initialState: nil)

    // MARK: - Public

    func start(atHertz hertz: Double) {
        tone.withLock { $0 = Tone(hertz: hertz, phase: 0) }
    }

    func stop() {
        tone.withLock { $0 = nil }
    }

    func render(
        frameCount: Int,
        sampleRate: Double,
        amplitude: Float,
        into buffers: UnsafeMutableAudioBufferListPointer
    ) {
        guard let sounding = tone.withLock({ $0 }) else {
            fillWithSilence(frameCount: frameCount, into: buffers)
            return
        }

        let reachedPhase = fillWithSineWave(
            sounding,
            frameCount: frameCount,
            sampleRate: sampleRate,
            amplitude: amplitude,
            into: buffers
        )
        tone.withLock { $0?.phase = reachedPhase }
    }

    // MARK: - Private

    private func fillWithSilence(frameCount: Int, into buffers: UnsafeMutableAudioBufferListPointer) {
        for frame in 0..<frameCount {
            write(0, atFrame: frame, into: buffers)
        }
    }

    private func fillWithSineWave(
        _ sounding: Tone,
        frameCount: Int,
        sampleRate: Double,
        amplitude: Float,
        into buffers: UnsafeMutableAudioBufferListPointer
    ) -> Double {
        let phaseIncrement = Self.radiansPerCycle * sounding.hertz / sampleRate
        var phase = sounding.phase
        for frame in 0..<frameCount {
            write(Float(sin(phase)) * amplitude, atFrame: frame, into: buffers)
            phase = (phase + phaseIncrement).truncatingRemainder(dividingBy: Self.radiansPerCycle)
        }
        return phase
    }

    private func write(_ sample: Float, atFrame frame: Int, into buffers: UnsafeMutableAudioBufferListPointer) {
        for buffer in buffers {
            UnsafeMutableBufferPointer<Float>(buffer)[frame] = sample
        }
    }
}

// MARK: - Tone

private struct Tone {
    var hertz: Double
    var phase: Double
}
