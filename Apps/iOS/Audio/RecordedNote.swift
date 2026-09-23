struct RecordedNote: Equatable, Sendable {
    let start: Int
    let loopStart: Int
    let loopEnd: Int
    let rootHertz: Double
    let sampleRate: Double
}
