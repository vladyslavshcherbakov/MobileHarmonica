import Foundation

protocol AudioEngineProtocol: AnyObject {
    func prepare() async throws
    func soundTones(at pitches: [Measurement<UnitFrequency>])
    func changeIntensity(to intensity: BreathIntensity)
    func silence()
}
