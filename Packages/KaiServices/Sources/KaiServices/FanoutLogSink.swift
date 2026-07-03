import Foundation

/// A `LogSink` that forwards every record to an ordered list of downstream sinks.
/// Used to write to both the unified log and the in-app collector at once.
public struct FanoutLogSink: LogSink {
    private let sinks: [LogSink]

    public init(_ sinks: [LogSink]) { self.sinks = sinks }

    public func write(_ level: LogLevel, category: String, message: String) {
        for sink in sinks { sink.write(level, category: category, message: message) }
    }
}
