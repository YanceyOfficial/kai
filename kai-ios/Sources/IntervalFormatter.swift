import Foundation

/// Formats a duration as a compact SRS-style interval caption ("<1m", "12m", "3h",
/// "5d", "2mo", "1y"). Pure and testable.
enum IntervalFormatter {
    static func short(_ seconds: TimeInterval) -> String {
        let s = max(0, seconds)
        let minutes = s / 60
        let hours = s / 3_600
        let days = s / 86_400
        if minutes < 1 { return "<1m" }
        if minutes < 60 { return "\(Int(minutes.rounded()))m" }
        if hours < 24 { return "\(Int(hours.rounded()))h" }
        if days < 30 { return "\(Int(days.rounded()))d" }
        if days < 365 { return "\(Int((days / 30).rounded()))mo" }
        return "\(Int((days / 365).rounded()))y"
    }

    static func short(from: Date, to: Date) -> String { short(to.timeIntervalSince(from)) }
}
