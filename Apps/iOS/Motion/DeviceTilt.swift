import CoreMotion
import HarmonicaCore
import UIKit

@MainActor
final class DeviceTilt: TiltProtocol {
    private static let secondsBetweenReadings = 1.0 / 60
    private static let slackAroundLevel = 0.05
    private static let gravityWhenFullyTilted = 0.5

    private let motion = CMMotionManager()

    // MARK: - Public

    func tiltToTheRight() -> AsyncStream<Double> {
        AsyncStream { continuation in
            guard motion.isDeviceMotionAvailable else { return continuation.finish() }

            motion.deviceMotionUpdateInterval = Self.secondsBetweenReadings
            motion.startDeviceMotionUpdates(to: .main) { reading, _ in
                guard let gravity = reading?.gravity else { return }

                MainActor.assumeIsolated {
                    _ = continuation.yield(Self.tiltToTheRight(with: gravity))
                }
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.stopFollowing() }
            }
        }
    }

    // MARK: - Private

    private static func tiltToTheRight(with gravity: CMAcceleration) -> Double {
        towardsLeaning(alongTheRightEdge(of: gravity))
    }

    private static func alongTheRightEdge(of gravity: CMAcceleration) -> Double {
        screenRightIsTheDeviceTop() ? gravity.y : -gravity.y
    }

    private static func towardsLeaning(_ gravity: Double) -> Double {
        let leaned = (gravity - slackAroundLevel) / (gravityWhenFullyTilted - slackAroundLevel)
        return min(1, max(0, leaned))
    }

    private static func screenRightIsTheDeviceTop() -> Bool {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation != .landscapeLeft
    }

    private func stopFollowing() {
        motion.stopDeviceMotionUpdates()
    }
}
