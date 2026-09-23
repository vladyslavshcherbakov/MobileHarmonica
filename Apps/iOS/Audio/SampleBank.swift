import Foundation

struct SampleBank: Sendable {
    let frames: [Float]
    let notes: [RecordedNote]

    // MARK: - Public

    func nearest(to hertz: Double) -> RecordedNote? {
        notes.min { distance(from: $0, to: hertz) < distance(from: $1, to: hertz) }
    }

    // MARK: - Private

    private func distance(from note: RecordedNote, to hertz: Double) -> Double {
        abs(log2(hertz / note.rootHertz))
    }
}
