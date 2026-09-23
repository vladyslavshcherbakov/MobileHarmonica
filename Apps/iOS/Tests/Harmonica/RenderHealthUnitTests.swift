import XCTest
@testable import MobileHarmonica

final class RenderHealthUnitTests: XCTestCase {
    // MARK: - Tests

    func test_renderHealth_whenABufferTakesLongerThanItsPeriod_countsItLate() {
        let health = RenderHealth()

        health.recordBuffer(tookNanoseconds: 1_000_000, periodNanoseconds: 1_333_333)
        health.recordBuffer(tookNanoseconds: 2_000_000, periodNanoseconds: 1_333_333)

        let report = health.collect()
        XCTAssertEqual(report.buffers, 2)
        XCTAssertEqual(report.lateBuffers, 1)
        XCTAssertEqual(report.slowestBufferSeconds, 0.002, accuracy: 0.000_001)
    }

    func test_renderHealth_whenCollected_startsCountingAfresh() {
        let health = RenderHealth()
        health.recordBuffer(tookNanoseconds: 2_000_000, periodNanoseconds: 1_333_333)
        health.recordVoices(12)

        _ = health.collect()

        let report = health.collect()
        XCTAssertEqual(report.lateBuffers, 0)
        XCTAssertEqual(report.mostVoices, 0)
    }

    func test_renderReport_whenABufferRanLate_namesItAndTheSlowest() {
        let report = RenderReport(
            buffers: 750,
            lateBuffers: 2,
            slowestBufferSeconds: 0.0015,
            bufferPeriodSeconds: 0.00133,
            mostVoices: 23,
            stolenVoices: 1,
            peak: 0.87,
            clippedSamples: 0
        )

        XCTAssertEqual(
            report.description,
            "render: 750 buffers, slowest 1.50 ms of 1.33, 2 late, up to 23 voices, 1 stolen, peak 0.87, 0 clipped samples"
        )
        XCTAssertTrue(report.hasTroubleThatCanBeHeard)
    }

    func test_renderReport_whenEveryBufferWasOnTimeAndNothingWasLost_isNoTrouble() {
        let report = RenderReport(
            buffers: 750,
            lateBuffers: 0,
            slowestBufferSeconds: 0.0004,
            bufferPeriodSeconds: 0.00133,
            mostVoices: 6,
            stolenVoices: 0,
            peak: 0.5,
            clippedSamples: 0
        )

        XCTAssertFalse(report.hasTroubleThatCanBeHeard)
    }
}
