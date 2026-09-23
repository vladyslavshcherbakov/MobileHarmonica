import HarmonicaCore
import os

@MainActor
final class LeaningPhone: TiltProtocol {
    private let watching = OSAllocatedUnfairLock(initialState: false)
    private var continuation: AsyncStream<Double>.Continuation?

    nonisolated init() {}

    var isWatched: Bool {
        watching.withLock { $0 }
    }

    func tiltToTheRight() -> AsyncStream<Double> {
        AsyncStream { continuation in
            self.continuation = continuation
            watching.withLock { $0 = true }
            continuation.onTermination = { [watching] _ in
                watching.withLock { $0 = false }
            }
        }
    }

    func lean(to fraction: Double) {
        continuation?.yield(fraction)
    }
}
