import Foundation

public struct BreathIntensity: Equatable, Sendable {
    private static let distanceAtFullPressure = 0.5

    public static let gainOnTheCentreLine = 0.2
    public static let full = BreathIntensity(gain: 1)

    public let gain: Double

    // MARK: - Public

    public init(gain: Double) {
        self.gain = gain
    }

    public init(at position: PositionOnHarmonica) {
        let pressed = min(1, abs(position.fractionAboveCentreLine) / Self.distanceAtFullPressure)
        let headroom = 1 - Self.gainOnTheCentreLine
        gain = ControlPrecision.quantised(Self.gainOnTheCentreLine + headroom * (1 - pow(1 - pressed, 2)))
    }
}
