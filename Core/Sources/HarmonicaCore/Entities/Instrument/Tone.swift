import Foundation

public struct Tone: Equatable, Sendable {
    public let pitch: Measurement<UnitFrequency>
    public let bendableSemitones: Double

    public init(pitch: Measurement<UnitFrequency>, bendableSemitones: Double) {
        self.pitch = pitch
        self.bendableSemitones = bendableSemitones
    }
}
