import Foundation

struct BreathIntensity: Equatable {
    static let gainOnTheCentreLine = 0.2

    let gain: Double
}

// MARK: - BreathIntensity + PositionOnHarmonica

extension BreathIntensity {
    private static let distanceAtFullPressure = 0.5

    init(at position: PositionOnHarmonica) {
        let pressed = min(1, abs(position.fractionAboveCentreLine) / Self.distanceAtFullPressure)
        let headroom = 1 - Self.gainOnTheCentreLine
        gain = ControlPrecision.quantised(Self.gainOnTheCentreLine + headroom * (1 - pow(1 - pressed, 2)))
    }
}
