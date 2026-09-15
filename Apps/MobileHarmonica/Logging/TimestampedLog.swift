import Foundation
import os

struct TimestampedLog {
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
        let timestamped = "\(Date.now.formatted(Self.timestampStyle)) \(line)"
        logger.info("\(timestamped, privacy: .public)")
    }
}
