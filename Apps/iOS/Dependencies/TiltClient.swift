import ComposableArchitecture
import HarmonicaCore

struct TiltClient: Sendable {
    var tiltToTheRight: @Sendable () async -> AsyncStream<Double>

    static func following(_ tilt: TiltProtocol) -> Self {
        TiltClient(tiltToTheRight: { await tilt.tiltToTheRight() })
    }
}

// MARK: - TiltClient + TestDependencyKey

extension TiltClient: TestDependencyKey {
    static let testValue = TiltClient(
        tiltToTheRight: {
            assertionFailure("TiltClient.tiltToTheRight is not provided")
            return AsyncStream { $0.finish() }
        }
    )
}

// MARK: - DependencyValues + TiltClient

extension DependencyValues {
    var tilt: TiltClient {
        get { self[TiltClient.self] }
        set { self[TiltClient.self] = newValue }
    }
}
