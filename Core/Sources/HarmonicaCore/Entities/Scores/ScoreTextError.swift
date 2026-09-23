public enum ScoreTextError: Error {
    case missingHeader(String)
    case unknownPosition(String)
    case badLine(String)
    case badPitch(String)
    case badLength(String)
}
