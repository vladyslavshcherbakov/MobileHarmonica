import Foundation

public struct BreathIntensity: Equatable {
    public static let gainOnTheCentreLine = 0.2

    public let gain: Double

    public init(gain: Double) {
        self.gain = gain
    }
}

// MARK: - BreathIntensity + PositionOnHarmonica

public extension BreathIntensity {
    private static let distanceAtFullPressure = 0.5

    init(at position: PositionOnHarmonica) {
        let pressed = min(1, abs(position.fractionAboveCentreLine) / Self.distanceAtFullPressure)
        let headroom = 1 - Self.gainOnTheCentreLine
        gain = ControlPrecision.quantised(Self.gainOnTheCentreLine + headroom * (1 - pow(1 - pressed, 2)))
    }
}

// MARK: - BreathIntensity + Score

public extension BreathIntensity {
    static let full = BreathIntensity(gain: 1)
}
