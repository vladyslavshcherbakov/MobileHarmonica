import HarmonicaCore
import os

@MainActor
final class LeaningPhone: TiltProtocol {
    private let watching = OSAllocatedUnfairLock(initialState: false)
    private var continuation: AsyncStream<Double>.Continuation?

    private(set) var timesWatched = 0

    nonisolated init() {}

    var isWatched: Bool {
        watching.withLock { $0 }
    }

    func tiltToTheRight() -> AsyncStream<Double> {
        AsyncStream { continuation in
            self.continuation = continuation
            timesWatched += 1
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
