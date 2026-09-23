enum RecordedHarmonicaError: Error {
    case noSamplesInTheBundle(String)
    case unreadable(String)
    case undecodable(String, any Error)
    case unnamedPitch(String)
    case tooShortToLoop(String, seconds: Double)
}
