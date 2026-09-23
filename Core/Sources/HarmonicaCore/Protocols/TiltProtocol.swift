@MainActor
public protocol TiltProtocol: Sendable {
    func tiltToTheRight() -> AsyncStream<Double>
}
