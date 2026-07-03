import Foundation

/// One captured log line, for the in-app Diagnostics screen and text export.
public struct LogRecord: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var timestamp: Date
    public var level: LogLevel
    public var category: String
    public var message: String

    public init(id: UUID = UUID(), timestamp: Date = .now, level: LogLevel, category: String, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
    }

    /// A single formatted line, e.g. `2026-07-03 17:40:12.482 [ERROR] review: Failed to …`.
    public var formatted: String {
        "\(Self.formatter.string(from: timestamp)) [\(level.label)] \(category): \(message)"
    }

    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()
}
