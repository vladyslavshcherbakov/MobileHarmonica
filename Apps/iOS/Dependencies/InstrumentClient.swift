import ComposableArchitecture
import HarmonicaCore

struct InstrumentClient: Sendable {
    var prepare: @Sendable (PlayerSettings) async throws(AudioEngineError) -> Void
    var adopt: @Sendable (PlayerSettings) async -> Void
    var cupHands: @Sendable (Double) async -> Void
    var silence: @Sendable () async -> Void

    static func playing(on harmonica: HarmonicaViewModel) -> Self {
        InstrumentClient(
            prepare: { (settings: PlayerSettings) async throws(AudioEngineError) -> Void in
                try await harmonica.prepare(adopting: settings)
            },
            adopt: { settings in await harmonica.adopt(settings) },
            cupHands: { leaning in await harmonica.cupHands(toLeaning: leaning) },
            silence: { await harmonica.silence() }
        )
    }
}

// MARK: - InstrumentClient + TestDependencyKey

extension InstrumentClient: TestDependencyKey {
    static let testValue = InstrumentClient(
        prepare: { _ in assertionFailure("InstrumentClient.prepare is not provided") },
        adopt: { _ in assertionFailure("InstrumentClient.adopt is not provided") },
        cupHands: { _ in assertionFailure("InstrumentClient.cupHands is not provided") },
        silence: { assertionFailure("InstrumentClient.silence is not provided") }
    )
}

// MARK: - DependencyValues + InstrumentClient

extension DependencyValues {
    var instrument: InstrumentClient {
        get { self[InstrumentClient.self] }
        set { self[InstrumentClient.self] = newValue }
    }
}
