#if arch(wasm32)
import Foundation
import HarmonicaCore

final class Instrument {
    private static let mostFingers = 16
    private static let doublesPerFinger = 3
    private static let outputBytes = 512 * 1024

    private let input = UnsafeMutableBufferPointer<Double>.allocate(
        capacity: mostFingers * doublesPerFinger
    )
    private let output = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: outputBytes)
    private let encoder = JSONEncoder()
    private let log = JavaScriptLog()
    private let playHarmonica = PlayHarmonica(
        tuning: RichterTuning(),
        audioEngine: JavaScriptAudioEngine(),
        log: JavaScriptLog()
    )

    // MARK: - Public

    var inputAddress: Int32 {
        address(of: UnsafeMutableRawPointer(input.baseAddress))
    }

    var outputAddress: Int32 {
        address(of: UnsafeMutableRawPointer(output.baseAddress))
    }

    func start() -> Int32 {
        publish(playHarmonica.harmonica)
    }

    func playAt(fingers: Int) -> Int32 {
        publish(playHarmonica.play(at: positions(of: fingers)))
    }

    func play(holes: Int, blowing: Bool) -> Int32 {
        publish(playHarmonica.play(self.holes(of: holes), breathing: blowing ? .blow : .draw))
    }

    func changeKey(toSliderPosition position: Int) -> Int32 {
        publish(playHarmonica.changeKey(to: HarmonicaKey(nearestSliderPosition: position)))
    }

    func changeStyle(at index: Int) -> Int32 {
        guard PlayingStyle.allCases.indices.contains(index) else { return publish(playHarmonica.harmonica) }

        return publish(playHarmonica.changeStyle(to: PlayingStyle.allCases[index]))
    }

    func changeMouth(holesWide: Int) -> Int32 {
        publish(playHarmonica.changeMouth(to: mouth(holesWide: holesWide)))
    }

    func shapeTone(pitch: Double, vibrato: Double) -> Int32 {
        publish(
            playHarmonica.shapeTone(
                PitchShaping(clamping: pitch),
                vibrato: VibratoDepth(clamping: vibrato)
            )
        )
    }

    func cupHands(to fraction: Double) -> Int32 {
        publish(playHarmonica.cupHands(to: CupDepth(clamping: fraction)))
    }

    func stopPlaying(ringingDown: Bool) -> Int32 {
        publish(playHarmonica.stopPlaying(ringingDown ? .ringsDown : .damped))
    }

    func tunes() -> Int32 {
        write(Score.tunes.map(TuneState.init))
    }

    func timing() -> Int32 {
        write(TimingState())
    }

    func reeds() -> Int32 {
        let tuning = RichterTuning()
        return write(
            Hole.allCases.flatMap { hole in
                [Breath.blow, .draw].map { ReedState(hole: hole, breath: $0, tuning: tuning) }
            }
        )
    }

    // MARK: - Private

    private func positions(of fingers: Int) -> [PositionOnHarmonica] {
        (0..<min(fingers, Self.mostFingers)).map { finger in
            let at = finger * Self.doublesPerFinger
            return PositionOnHarmonica(
                fractionFromLeftEdge: input[at],
                fractionAboveCentreLine: input[at + 1],
                fractionCoveredEitherSide: input[at + 2]
            )
        }
    }

    private func holes(of count: Int) -> [Hole] {
        (0..<min(count, Hole.allCases.count)).compactMap(hole(at:))
    }

    private func hole(at index: Int) -> Hole? {
        let written = input[index]
        guard let number = Int(exactly: written.rounded()), let hole = Hole(rawValue: number) else {
            log.record("the page asked to sound \(written), which is not a hole")
            return nil
        }

        return hole
    }

    private func mouth(holesWide: Int) -> MouthMeasure {
        guard let width = MouthWidth(rawValue: holesWide) else { return .theContactItself }

        return .holesWide(width)
    }

    private func publish(_ harmonica: Harmonica) -> Int32 {
        write(HarmonicaState(harmonica))
    }

    private func write(_ value: some Encodable) -> Int32 {
        guard let encoded = try? encoder.encode(value), encoded.count <= output.count else { return 0 }

        _ = encoded.copyBytes(to: output)
        return Int32(encoded.count)
    }

    private func address(of pointer: UnsafeMutableRawPointer?) -> Int32 {
        Int32(UInt(bitPattern: pointer))
    }
}
#endif
