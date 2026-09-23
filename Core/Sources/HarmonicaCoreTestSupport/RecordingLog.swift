import Foundation
import HarmonicaCore

public final class RecordingLog: LogProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var recordedLines: [String] = []

    public init() {}

    public var lines: [String] {
        lock.withLock { recordedLines }
    }

    public func record(_ line: String) {
        lock.withLock { recordedLines.append(line) }
    }

    public func recordSample(_ line: String) {}
}
