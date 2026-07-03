import Foundation
import KaiCore
import KaiFSRS

/// One day's review count, for the stats bar chart.
struct DayBar: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
}

/// Memory-maturity buckets, from freshly introduced to well-consolidated.
enum MaturityBucket: String, CaseIterable, Identifiable {
    case new = "New", learning = "Learning", young = "Young", mature = "Mature"
    var id: String { rawValue }
}

/// A maturity bucket with its word count.
struct MaturityCount: Identifiable {
    let bucket: MaturityBucket
    let count: Int
    var id: String { bucket.rawValue }
}

/// One point on the deck's aggregate forgetting curve: predicted average recall on a
/// given number of days from now, assuming no further review.
struct RecallPoint: Identifiable {
    let dayOffset: Int
    let recall: Double
    var id: Int { dayOffset }
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

    /// Consecutive days with at least one review, ending today (or yesterday if today
    /// has no reviews yet, so the streak survives until midnight). Zero when neither has.
    static func streak(reviewDates: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        let days = Set(reviewDates.map { calendar.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        var day = days.contains(today) ? today : yesterday
        guard days.contains(day) else { return 0 }
        var count = 0
        while days.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    /// Buckets entries by memory maturity. `states` pairs each entry's learning state
    /// with its stability (days). Young/Mature split at 21 days (the common threshold).
    static func maturity(_ states: [(state: LearningState, stability: Double)], matureDays: Double = 21) -> [MaturityCount] {
        var counts: [MaturityBucket: Int] = [:]
        for item in states {
            let bucket: MaturityBucket
            switch item.state {
            case .new: bucket = .new
            case .learning, .relearning: bucket = .learning
            case .review: bucket = item.stability >= matureDays ? .mature : .young
            }
            counts[bucket, default: 0] += 1
        }
        return MaturityBucket.allCases.map { MaturityCount(bucket: $0, count: counts[$0] ?? 0) }
    }

    /// The deck's aggregate forgetting curve: average predicted recall for each day from
    /// now up to `overDays`, assuming no further review. `memories` gives each reviewed
    /// entry's stability and days elapsed since its last review; entries with no memory
    /// yet (stability 0) are excluded. Empty input yields an empty curve.
    static func forgettingCurve(
        _ memories: [(stability: Double, elapsedDays: Double)],
        overDays: Int = 30,
        scheduler: FSRSScheduler = FSRSScheduler()
    ) -> [RecallPoint] {
        let active = memories.filter { $0.stability > 0 }
        guard !active.isEmpty else { return [] }
        return (0...overDays).map { offset in
            let total = active.reduce(0.0) { sum, m in
                sum + scheduler.retrievability(elapsedDays: m.elapsedDays + Double(offset), stability: m.stability)
            }
            return RecallPoint(dayOffset: offset, recall: total / Double(active.count))
        }
    }

    /// How many memories will drop below `threshold` recall within `days` — the "at-risk"
    /// count worth reviewing soon.
    static func atRisk(
        _ memories: [(stability: Double, elapsedDays: Double)],
        threshold: Double = 0.9,
        within days: Int = 7,
        scheduler: FSRSScheduler = FSRSScheduler()
    ) -> Int {
        memories.filter { $0.stability > 0 }.reduce(0) { count, m in
            let r = scheduler.retrievability(elapsedDays: m.elapsedDays + Double(days), stability: m.stability)
            return r < threshold ? count + 1 : count
        }
    }
}
