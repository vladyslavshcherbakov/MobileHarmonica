import HarmonicaCoreTestSupport
import XCTest
@testable import MobileHarmonica

@MainActor
final class FastPlayingBudgetIntegrationTests: XCTestCase {
    private static let gestures = 2000
    private static let longestAverageSecondsPerGesture = 0.002
    private static let shortBufferFrames = 64
    private static let shortBuffersPerGesture = 6
    private static let largestShareOfABufferSpentRendering = 0.25
    private static let shareOfBuffersAllowedToBeInterrupted = 0.001

    private let offlineEngine = OfflineSamplerEngine()
    private lazy var environment = TestEnvironment(audioEngine: offlineEngine)

    // MARK: - Tests

    func test_fastPlaying_whenChordsBreathsBendsAndLeansChangeTogether_answersEachGestureWellInsideAFrame() async {
        let screen = await followingThePhone()
        var answering = Duration.zero

        for step in 0..<Self.gestures {
            answering += await timed { await self.perform(FastGesture(step: step), on: screen) }
        }

        let averageSeconds = seconds(of: answering) / Double(Self.gestures)
        report("average per gesture: \(averageSeconds * 1000) ms")
        XCTAssertLessThan(
            averageSeconds,
            Self.longestAverageSecondsPerGesture,
            "a frame at 120 Hz is 8.3 ms, and a gesture has to leave most of it to drawing"
        )
    }

    func test_fastPlaying_whenChordsBreathsBendsAndLeansChangeTogether_rendersShortBuffersWellInsideTheirPeriodSaveOneInAThousand() async {
        let screen = await followingThePhone()
        var renderingOfEachBuffer: [Duration] = []

        for step in 0..<Self.gestures {
            await perform(FastGesture(step: step), on: screen)
            renderingOfEachBuffer += RenderedSound.durations(
                ofRendering: Self.shortBuffersPerGesture,
                framesEach: Self.shortBufferFrames,
                from: offlineEngine.sampler
            )
        }

        let bufferSeconds = Double(Self.shortBufferFrames) / RenderedSound.sampleRate
        let secondsOfEachBufferSlowestLast = renderingOfEachBuffer.map(seconds(of:)).sorted()
        let slowestBufferNotInterrupted = secondsOfEachBufferSlowestLast[
            Int(Double(secondsOfEachBufferSlowestLast.count) * (1 - Self.shareOfBuffersAllowedToBeInterrupted))
        ]
        report(
            "a buffer of \(Self.shortBufferFrames) frames lasts \(bufferSeconds * 1000) ms; rendering one took"
                + " \(average(of: secondsOfEachBufferSlowestLast) * 1000) ms on average,"
                + " \(slowestBufferNotInterrupted * 1000) ms at the 99.9th percentile"
                + " and \((secondsOfEachBufferSlowestLast.last ?? 0) * 1000) ms at worst"
        )
        XCTAssertLessThan(
            slowestBufferNotInterrupted / bufferSeconds,
            Self.largestShareOfABufferSpentRendering,
            "a buffer rendered past a quarter of its period leaves a slower phone no margin before it clicks"
        )
    }

    func test_fastPlaying_whenTheLastGestureHoldsAChord_isStillSounding() async {
        let screen = await followingThePhone()
        for step in 0..<Self.gestures {
            await perform(FastGesture(step: step), on: screen)
        }

        screen.touchStrip(with: FastGesture(step: 1).fingers)

        XCTAssertGreaterThan(
            RenderedSound.loudness(of: offlineEngine.sampler),
            0.01,
            "a scenario that silenced the sampler would make the render budget meaningless"
        )
    }

    // MARK: - Helpers

    private func followingThePhone() async -> HarmonicaScreenDriver {
        let screen = await environment.harmonicaScreen()
        let following = Task { await screen.followThePhone() }
        addTeardownBlock { following.cancel() }
        _ = await waitUntil { self.environment.phone.isWatched }
        return screen
    }

    private func perform(_ gesture: FastGesture, on screen: HarmonicaScreenDriver) async {
        environment.phone.lean(to: gesture.lean)
        screen.touchSquare(pitch: gesture.pitch, vibrato: gesture.vibrato)
        if gesture.fingers.isEmpty {
            screen.liftFromTheStrip()
        } else {
            screen.touchStrip(with: gesture.fingers)
        }
        await Task.yield()
    }

    private func timed(_ work: () async -> Void) async -> Duration {
        let clock = ContinuousClock()
        let started = clock.now
        await work()
        return clock.now - started
    }

    private func average(of values: [Double]) -> Double {
        values.reduce(0, +) / Double(max(1, values.count))
    }

    private func seconds(of duration: Duration) -> Double {
        let (seconds, attoseconds) = duration.components
        return Double(seconds) + Double(attoseconds) / 1e18
    }

    private func report(_ line: String) {
        let attachment = XCTAttachment(string: line)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - FastGesture

private struct FastGesture {
    private static let holesTheHandCrosses = 8
    private static let gesturesPerBreath = 5
    private static let gesturesPerLift = 7
    private static let fractionAboveTheLineWhenBlowing = 0.3
    private static let contactHalfWidth = 0.03

    let fingers: [StripFinger]
    let pitch: Double
    let vibrato: Double
    let lean: Double

    // MARK: - Public

    init(step: Int) {
        fingers = Self.fingers(at: step)
        pitch = sin(Double(step) * 0.37)
        vibrato = Double(step % 10) / 10
        lean = Double(step % 20) / 20
    }

    // MARK: - Private

    private static func fingers(at step: Int) -> [StripFinger] {
        guard !step.isMultiple(of: gesturesPerLift) else { return [] }

        let lowestHole = step % holesTheHandCrosses
        let holesInTheChord = step.isMultiple(of: 3) ? 3 : 2
        return (0..<holesInTheChord).map { offset in
            StripFinger(
                fractionFromLeftEdge: (Double(lowestHole + offset) + 0.5) / 10,
                fractionAboveCentreLine: breath(at: step),
                fractionCoveredEitherSide: contactHalfWidth
            )
        }
    }

    private static func breath(at step: Int) -> Double {
        (step / gesturesPerBreath).isMultiple(of: 2)
            ? fractionAboveTheLineWhenBlowing
            : -fractionAboveTheLineWhenBlowing
    }
}
