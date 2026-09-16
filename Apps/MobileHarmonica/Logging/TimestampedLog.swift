import Foundation
import os

struct TimestampedLog: LogProtocol {
    private static let timestampStyle = Date.ISO8601FormatStyle(timeZone: .gmt)
        .year()
        .month()
        .day()
        .dateSeparator(.dash)
        .dateTimeSeparator(.space)
        .time(includingFractionalSeconds: true)

    private let logger: Logger

    init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    func record(_ line: String) {
        let timestamped = stamped(line)
        logger.info("\(timestamped, privacy: .public)")
    }

    func recordSample(_ line: String) {
        let timestamped = stamped(line)
        logger.debug("\(timestamped, privacy: .public)")
    }

    private func stamped(_ line: String) -> String {
        "\(Date.now.formatted(Self.timestampStyle)) \(line)"
    }
}
