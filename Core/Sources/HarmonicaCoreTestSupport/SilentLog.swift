import HarmonicaCore

public struct SilentLog: LogProtocol {
    public init() {}

    public func record(_ line: String) {}

    public func recordSample(_ line: String) {}
}
