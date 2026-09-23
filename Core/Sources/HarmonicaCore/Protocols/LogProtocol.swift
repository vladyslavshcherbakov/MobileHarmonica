public protocol LogProtocol: Sendable {
    func record(_ line: String)
    func recordSample(_ line: String)
}
