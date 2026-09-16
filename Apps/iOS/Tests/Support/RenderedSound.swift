import AVFoundation
@testable import MobileHarmonica

struct RenderedSound {
    static let sampleRate = 48000.0
    static let framesPerBuffer = 960

    static func frequency(of oscillator: Oscillator) -> Double {
        risingEdgeFrequency(in: buffer(from: oscillator))
    }

    static func settle(_ oscillator: Oscillator) {
        for _ in 0..<3 {
            _ = buffer(from: oscillator)
        }
    }

    private static func buffer(from oscillator: Oscillator) -> [Float] {
        var samples = [Float](repeating: 0, count: framesPerBuffer)
        let list = AudioBufferList.allocate(maximumBuffers: 1)
        defer { free(list.unsafeMutablePointer) }

        samples.withUnsafeMutableBufferPointer { written in
            list[0] = AudioBuffer(
                mNumberChannels: 1,
                mDataByteSize: UInt32(framesPerBuffer * MemoryLayout<Float>.size),
                mData: written.baseAddress
            )
            oscillator.render(
                frameCount: framesPerBuffer,
                sampleRate: sampleRate,
                amplitude: 1,
                into: list
            )
        }
        return samples
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
