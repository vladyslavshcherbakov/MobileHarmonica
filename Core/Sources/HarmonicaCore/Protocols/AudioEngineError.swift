public enum AudioEngineError: Error, Equatable {
    case noRecordings
    case recordingUnreadable(String)
    case outputRefused
}
