import Foundation

struct RenderReport: CustomStringConvertible {
    let buffers: Int
    let lateBuffers: Int
    let slowestBufferSeconds: Double
    let bufferPeriodSeconds: Double
    let mostVoices: Int
    let stolenVoices: Int
    let peak: Double
    let clippedSamples: Int

    var soundedSomething: Bool {
        mostVoices > 0
    }

    var hasTroubleThatCanBeHeard: Bool {
        lateBuffers > 0 || stolenVoices > 0 || clippedSamples > 0
    }

    var description: String {
        "render: \(buffers) buffers, slowest \(Self.milliseconds(slowestBufferSeconds)) ms"
            + " of \(Self.milliseconds(bufferPeriodSeconds)), \(lateBuffers) late,"
            + " up to \(mostVoices) voices, \(stolenVoices) stolen,"
            + " peak \(Self.hundredths(peak)), \(clippedSamples) clipped samples"
    }

    private static func milliseconds(_ seconds: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), seconds * 1000)
    }

    private static func hundredths(_ value: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
