import Foundation

protocol AudioEngineProtocol: AnyObject {
    func prepare() async throws
    func startTone(at pitch: Measurement<UnitFrequency>)
    func stopTone()
}
