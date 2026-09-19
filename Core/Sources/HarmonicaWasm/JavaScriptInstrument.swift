#if arch(wasm32)
import HarmonicaCore

final class JavaScriptAudioEngine: AudioEngineProtocol {
    func prepare() async throws {}

    func soundTones(_ tones: [Tone], as change: ToneChange) {
        var flattened = tones.flatMap { [$0.pitch.converted(to: .hertz).value, $0.bendableSemitones] }
        flattened.withUnsafeMutableBufferPointer { buffer in
            soundTonesInJavaScript(buffer.baseAddress, Int32(tones.count), Int32(number(of: change)))
        }
    }

    func changeIntensity(to intensity: BreathIntensity) {
        changeIntensityInJavaScript(intensity.gain)
    }

    func changeBend(to depth: BendDepth) {
        changeBendInJavaScript(depth.fraction)
    }

    func changeVibrato(to depth: VibratoDepth) {
        changeVibratoInJavaScript(depth.fraction)
    }

    func cupHands(to depth: CupDepth) {
        cupHandsInJavaScript(depth.fraction)
    }

    func silence(_ release: ReedRelease) {
        silenceInJavaScript(release == .ringsDown ? 0 : 1)
    }

    private func number(of change: ToneChange) -> Int {
        switch change {
        case .slide: 0
        case .newReed: 1
        case .breathReversed: 2
        }
    }
}

// MARK: - JavaScriptLog

struct JavaScriptLog: LogProtocol {
    func record(_ line: String) {
        write(line, asSample: false)
    }

    func recordSample(_ line: String) {
        write(line, asSample: true)
    }

    private func write(_ line: String, asSample: Bool) {
        var utf8 = Array(line.utf8)
        utf8.withUnsafeMutableBufferPointer { buffer in
            logInJavaScript(buffer.baseAddress, Int32(buffer.count), asSample ? 1 : 0)
        }
    }
}

// MARK: - What JavaScript provides

@_extern(wasm, module: "harmonica", name: "soundTones")
func soundTonesInJavaScript(_ tones: UnsafeMutablePointer<Double>?, _ count: Int32, _ change: Int32)

@_extern(wasm, module: "harmonica", name: "changeIntensity")
func changeIntensityInJavaScript(_ gain: Double)

@_extern(wasm, module: "harmonica", name: "changeBend")
func changeBendInJavaScript(_ fraction: Double)

@_extern(wasm, module: "harmonica", name: "changeVibrato")
func changeVibratoInJavaScript(_ fraction: Double)

@_extern(wasm, module: "harmonica", name: "cupHands")
func cupHandsInJavaScript(_ fraction: Double)

@_extern(wasm, module: "harmonica", name: "silence")
func silenceInJavaScript(_ release: Int32)

@_extern(wasm, module: "harmonica", name: "log")
func logInJavaScript(_ line: UnsafeMutablePointer<UInt8>?, _ length: Int32, _ isSample: Int32)
#endif
