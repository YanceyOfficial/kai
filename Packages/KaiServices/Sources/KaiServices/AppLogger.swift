import Foundation
import os

/// Severity level for a log record.
public enum LogLevel: Int, Comparable, Sendable {
    case debug, info, warning, error
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A destination for log records. Injectable so tests can capture output.
public protocol LogSink: Sendable {
    func write(_ level: LogLevel, category: String, message: String)
}

/// Production sink backed by the unified logging system (`os.Logger`).
public struct OSLogSink: LogSink {
    private let subsystem: String
    public init(subsystem: String = "app.yancey.kai") { self.subsystem = subsystem }

    public func write(_ level: LogLevel, category: String, message: String) {
        let logger = Logger(subsystem: subsystem, category: category)
        switch level {
        case .debug: logger.debug("\(message, privacy: .public)")
        case .info: logger.info("\(message, privacy: .public)")
        case .warning: logger.warning("\(message, privacy: .public)")
        case .error: logger.error("\(message, privacy: .public)")
        }
    }
}

/// The app's logging facade. Filters by minimum level, then forwards to a sink.
public struct AppLogger: Sendable {
    private let sink: LogSink
    private let minimumLevel: LogLevel

    public init(sink: LogSink, minimumLevel: LogLevel = .debug) {
        self.sink = sink
        self.minimumLevel = minimumLevel
    }

    private func log(_ level: LogLevel, _ message: String, _ category: String) {
        guard level >= minimumLevel else { return }
        sink.write(level, category: category, message: message)
    }

    public func debug(_ message: String, category: String) { log(.debug, message, category) }
    public func info(_ message: String, category: String) { log(.info, message, category) }
    public func warning(_ message: String, category: String) { log(.warning, message, category) }
    public func error(_ message: String, category: String) { log(.error, message, category) }
}
