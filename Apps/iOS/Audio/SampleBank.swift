import Foundation

struct SampleBank {
    static let empty = SampleBank(frames: [], notes: [])

    let frames: [Float]
    let notes: [RecordedNote]

    // MARK: - Public

    var isEmpty: Bool {
        notes.isEmpty
    }

    func nearest(to hertz: Double) -> RecordedNote? {
        notes.min { distance(from: $0, to: hertz) < distance(from: $1, to: hertz) }
    }

    // MARK: - Private

    private func distance(from note: RecordedNote, to hertz: Double) -> Double {
        abs(log2(hertz / note.rootHertz))
    }
}

// MARK: - RecordedNote

struct RecordedNote: Equatable {
    let start: Int
    let loopStart: Int
    let loopEnd: Int
    let rootHertz: Double
    let sampleRate: Double
}
