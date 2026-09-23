import Foundation
import Synchronization

final class RenderHealth: Sendable {
    private let buffers = Atomic<Int>(0)
    private let lateBuffers = Atomic<Int>(0)
    private let slowestBufferNanoseconds = Atomic<UInt64>(0)
    private let bufferPeriodNanoseconds = Atomic<UInt64>(0)
    private let mostVoices = Atomic<Int>(0)
    private let stolenVoices = Atomic<Int>(0)
    private let peakBitPattern = Atomic<UInt64>(0)
    private let clippedSamples = Atomic<Int>(0)

    // MARK: - Public

    func recordBuffer(tookNanoseconds took: UInt64, periodNanoseconds period: UInt64) {
        buffers.wrappingAdd(1, ordering: .relaxed)
        bufferPeriodNanoseconds.store(period, ordering: .relaxed)
        raise(slowestBufferNanoseconds, to: took)
        guard took > period else { return }

        lateBuffers.wrappingAdd(1, ordering: .relaxed)
    }

    func recordVoices(_ count: Int) {
        raise(mostVoices, to: count)
    }

    func recordStolenVoices(_ count: Int) {
        guard count > 0 else { return }

        stolenVoices.wrappingAdd(count, ordering: .relaxed)
    }

    func recordOutput(peak: Float, clippedSamples clipped: Int) {
        raise(peakBitPattern, to: Double(peak).bitPattern)
        guard clipped > 0 else { return }

        clippedSamples.wrappingAdd(clipped, ordering: .relaxed)
    }

    func collect() -> RenderReport {
        RenderReport(
            buffers: buffers.exchange(0, ordering: .relaxed),
            lateBuffers: lateBuffers.exchange(0, ordering: .relaxed),
            slowestBufferSeconds: Self.seconds(slowestBufferNanoseconds.exchange(0, ordering: .relaxed)),
            bufferPeriodSeconds: Self.seconds(bufferPeriodNanoseconds.load(ordering: .relaxed)),
            mostVoices: mostVoices.exchange(0, ordering: .relaxed),
            stolenVoices: stolenVoices.exchange(0, ordering: .relaxed),
            peak: Double(bitPattern: peakBitPattern.exchange(0, ordering: .relaxed)),
            clippedSamples: clippedSamples.exchange(0, ordering: .relaxed)
        )
    }

    // MARK: - Private

    private static func seconds(_ nanoseconds: UInt64) -> Double {
        Double(nanoseconds) / 1_000_000_000
    }

    private func raise(_ highest: borrowing Atomic<UInt64>, to value: UInt64) {
        var current = highest.load(ordering: .relaxed)
        while value > current {
            let (exchanged, original) = highest.compareExchange(
                expected: current,
                desired: value,
                ordering: .relaxed
            )
            guard !exchanged else { return }

            current = original
        }
    }

    private func raise(_ highest: borrowing Atomic<Int>, to value: Int) {
        var current = highest.load(ordering: .relaxed)
        while value > current {
            let (exchanged, original) = highest.compareExchange(
                expected: current,
                desired: value,
                ordering: .relaxed
            )
            guard !exchanged else { return }

            current = original
        }
    }
}
