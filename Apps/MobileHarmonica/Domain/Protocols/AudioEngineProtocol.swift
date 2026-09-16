import Foundation

protocol AudioEngineProtocol: AnyObject {
    func prepare() async throws
    func soundTone(at pitch: Measurement<UnitFrequency>)
    func silence()
}
