import Foundation
import HarmonicaCore
import HarmonicaCoreTestSupport
@testable import MobileHarmonica

enum SineSamples {
    static let rootHertz = 440.0
    static let sampleRate = 48000.0

    private static let frameCount = 4800

    static func bank() -> SampleBank {
        SampleBank(frames: cycles(), notes: [note()])
    }

    private static func cycles() -> [Float] {
        (0..<frameCount).map {
            Float(sin(2 * Double.pi * rootHertz * Double($0) / sampleRate))
        }
    }

    private static func note() -> RecordedNote {
        RecordedNote(
            start: 0,
            loopStart: 0,
            loopEnd: frameCount,
            rootHertz: rootHertz,
            sampleRate: sampleRate
        )
    }
}
