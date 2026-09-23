import AVFoundation
import HarmonicaCore
import HarmonicaCoreTestSupport
@testable import MobileHarmonica

struct RenderedSound {
    static let sampleRate = 48000.0
    static let framesPerBuffer = 960

    static func frequency(of sampler: ReedSampler) -> Double {
        risingEdgeFrequency(in: buffer(from: sampler))
    }

    static func loudness(of sampler: ReedSampler) -> Double {
        rootMeanSquare(of: buffer(from: sampler))
    }

    static func settle(_ sampler: ReedSampler) {
        render(3, from: sampler)
    }

    static func render(_ buffers: Int, from sampler: ReedSampler) {
        for _ in 0..<buffers {
            _ = buffer(from: sampler)
        }
    }

    static func durations(ofRendering buffers: Int, framesEach frames: Int, from sampler: ReedSampler) -> [Duration] {
        var samples = [Float](repeating: 0, count: frames)
        let list = AudioBufferList.allocate(maximumBuffers: 1)
        defer { free(list.unsafeMutablePointer) }

        let clock = ContinuousClock()
        return samples.withUnsafeMutableBufferPointer { written in
            list[0] = AudioBuffer(
                mNumberChannels: 1,
                mDataByteSize: UInt32(frames * MemoryLayout<Float>.size),
                mData: written.baseAddress
            )
            return (0..<buffers).map { _ in
                clock.measure {
                    sampler.render(frameCount: frames, sampleRate: sampleRate, amplitude: 1, into: list)
                }
            }
        }
    }

    private static func buffer(from sampler: ReedSampler) -> [Float] {
        var samples = [Float](repeating: 0, count: framesPerBuffer)
        let list = AudioBufferList.allocate(maximumBuffers: 1)
        defer { free(list.unsafeMutablePointer) }

        samples.withUnsafeMutableBufferPointer { written in
            list[0] = AudioBuffer(
                mNumberChannels: 1,
                mDataByteSize: UInt32(framesPerBuffer * MemoryLayout<Float>.size),
                mData: written.baseAddress
            )
            sampler.render(
                frameCount: framesPerBuffer,
                sampleRate: sampleRate,
                amplitude: 1,
                into: list
            )
        }
        return samples
    }

    private static func rootMeanSquare(of samples: [Float]) -> Double {
        let squares = samples.reduce(0.0) { $0 + Double($1) * Double($1) }
        return (squares / Double(samples.count)).squareRoot()
    }

    private static func risingEdgeFrequency(in samples: [Float]) -> Double {
        let edges = risingEdges(in: samples)
        guard let first = edges.first, let last = edges.last, edges.count > 1 else { return 0 }

        return sampleRate * Double(edges.count - 1) / Double(last - first)
    }

    private static func risingEdges(in samples: [Float]) -> [Int] {
        (1..<samples.count).filter { samples[$0 - 1] <= 0 && samples[$0] > 0 }
    }
}
