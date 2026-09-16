@testable import MobileHarmonica

struct SilentLog: LogProtocol {
    func record(_ line: String) {}

    func recordSample(_ line: String) {}
}
