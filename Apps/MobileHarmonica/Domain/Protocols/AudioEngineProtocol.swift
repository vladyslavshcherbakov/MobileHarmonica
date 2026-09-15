import Foundation

protocol AudioEngineProtocol: AnyObject {
    func prepare() throws
    func startTone(at pitch: Measurement<UnitFrequency>)
    func stopTone()
}
