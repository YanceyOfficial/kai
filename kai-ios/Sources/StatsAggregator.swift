import Foundation

/// One day's review count, for the stats bar chart.
struct DayBar: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
}

/// Pure aggregation for the statistics dashboard. Takes plain arrays (dates, flags)
/// so it is fully testable without SwiftData or a renderer.
enum StatsAggregator {
    /// Buckets `timestamps` into the last `days` calendar days (oldest first), filling
    /// empty days with zero. Timestamps outside the window are ignored.
    static func reviewsByDay(
        _ timestamps: [Date],
        lastDays days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [DayBar] {
        let startOfToday = calendar.startOfDay(for: now)
        var counts: [Date: Int] = [:]
        for timestamp in timestamps {
            let day = calendar.startOfDay(for: timestamp)
            if let diff = calendar.dateComponents([.day], from: day, to: startOfToday).day,
               diff >= 0, diff < days {
                counts[day, default: 0] += 1
            }
        }
        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday)!
            return DayBar(date: day, count: counts[day] ?? 0)
        }
    }

    /// The fraction of correct answers, or `nil` when there are no reviews yet.
    static func accuracy(_ correctFlags: [Bool]) -> Double? {
        guard !correctFlags.isEmpty else { return nil }
        return Double(correctFlags.filter { $0 }.count) / Double(correctFlags.count)
    }
}
