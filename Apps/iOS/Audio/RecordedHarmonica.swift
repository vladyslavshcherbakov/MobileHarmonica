import AVFoundation
import HarmonicaCore

enum RecordedHarmonica {
    static let folder = "Samples"

    private static let loopStartSeconds = 1.0
    private static let loopEndSeconds = 4.0
    private static let shortestLoopSeconds = 0.2
    private static let semitonesAboveTheLabel = 12
    private static let semitonesAboveC = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]

    // MARK: - Public

    static func bank() throws -> SampleBank {
        let urls = Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: folder) ?? []
        guard !urls.isEmpty else { throw RecordedHarmonicaError.noSamplesInTheBundle(folder) }

        var frames: [Float] = []
        var notes: [RecordedNote] = []
        for url in urls {
            notes.append(try read(url, appendingTo: &frames))
        }
        return SampleBank(frames: frames, notes: notes)
    }

    // MARK: - Private

    private static func read(_ url: URL, appendingTo frames: inout [Float]) throws -> RecordedNote {
        let name = url.deletingPathExtension().lastPathComponent
        let file = try AVAudioFile(forReading: url)
        let mono = try monoFrames(of: file, named: name)
        let loop = try loopBounds(framesPerSecond: file.processingFormat.sampleRate, within: mono.count, named: name)

        let start = frames.count
        frames.append(contentsOf: mono[0..<loop.upperBound])
        return RecordedNote(
            start: start,
            loopStart: loop.lowerBound,
            loopEnd: loop.upperBound,
            rootHertz: try rootHertz(of: name),
            sampleRate: file.processingFormat.sampleRate
        )
    }

    private static func monoFrames(of file: AVAudioFile, named name: String) throws -> [Float] {
        let format = file.processingFormat
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) else {
            throw RecordedHarmonicaError.unreadable(name)
        }

        try file.read(into: buffer)
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else {
            throw RecordedHarmonicaError.unreadable(name)
        }

        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(format.channelCount)
        var mono = [Float](repeating: 0, count: frameCount)
        for channel in 0..<channelCount {
            for frame in 0..<frameCount {
                mono[frame] += channels[channel][frame] / Float(channelCount)
            }
        }
        return mono
    }

    private static func loopBounds(
        framesPerSecond: Double,
        within frameCount: Int,
        named name: String
    ) throws -> Range<Int> {
        let start = Int(loopStartSeconds * framesPerSecond)
        let end = min(frameCount, Int(loopEndSeconds * framesPerSecond))
        guard end - start >= Int(shortestLoopSeconds * framesPerSecond) else {
            throw RecordedHarmonicaError.tooShortToLoop(name, seconds: Double(frameCount) / framesPerSecond)
        }

        return start..<end
    }

    private static func rootHertz(of name: String) throws -> Double {
        guard let number = midiNumber(of: name) else { throw RecordedHarmonicaError.unnamedPitch(name) }

        return MIDINote(number: number + semitonesAboveTheLabel).pitch.converted(to: .hertz).value
    }

    private static func midiNumber(of name: String) -> Int? {
        guard let octave = name.last.flatMap({ Int(String($0)) }) else { return nil }

        var letters = name.dropLast()
        let isSharp = letters.last == "#"
        if isSharp { letters = letters.dropLast() }
        guard let semitones = letters.last.flatMap({ semitonesAboveC[String($0)] }) else { return nil }

        return semitones + (isSharp ? 1 : 0) + 12 * (octave + 1)
    }
}

// MARK: - RecordedHarmonicaError

enum RecordedHarmonicaError: Error {
    case noSamplesInTheBundle(String)
    case unreadable(String)
    case unnamedPitch(String)
    case tooShortToLoop(String, seconds: Double)
}
