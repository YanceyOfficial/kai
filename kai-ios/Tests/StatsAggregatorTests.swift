import Testing
import Foundation
import KaiCore
@testable import kai_ios

@Suite("StatsAggregator")
struct StatsAggregatorTests {
    // A fixed clock and UTC calendar so day bucketing is deterministic.
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private let now = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14 22:13:20 UTC

    @Test("Returns one bar per day, oldest first, ending today")
    func shapeAndOrder() {
        let bars = StatsAggregator.reviewsByDay([], lastDays: 7, now: now, calendar: calendar)
        #expect(bars.count == 7)
        #expect(bars.map(\.count).allSatisfy { $0 == 0 })
        // Chronological: each date is one day after the previous.
        for i in 1..<bars.count {
            let gap = calendar.dateComponents([.day], from: bars[i - 1].date, to: bars[i].date).day
            #expect(gap == 1)
        }
        // Last bar is today.
        #expect(calendar.isDate(bars.last!.date, inSameDayAs: now))
    }

    @Test("Counts reviews into the right day and ignores out-of-window timestamps")
    func counting() {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let longAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        let stamps = [today, today, today, yesterday, longAgo]

        let bars = StatsAggregator.reviewsByDay(stamps, lastDays: 7, now: now, calendar: calendar)
        #expect(bars.last?.count == 3)          // three today
        #expect(bars[bars.count - 2].count == 1) // one yesterday
        #expect(bars.map(\.count).reduce(0, +) == 4) // longAgo excluded
    }

    @Test("Accuracy is the fraction correct, nil when empty")
    func accuracy() {
        #expect(StatsAggregator.accuracy([]) == nil)
        #expect(StatsAggregator.accuracy([true, true, false, true]) == 0.75)
        #expect(StatsAggregator.accuracy([false, false]) == 0.0)
    }

    @Test("Streak counts consecutive review days ending today or yesterday")
    func streak() {
        let today = calendar.startOfDay(for: now)
        func day(_ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: today)! }

        #expect(StatsAggregator.streak(reviewDates: [], now: now, calendar: calendar) == 0)
        // today, -1, -2 → 3; a gap at -3 stops the count.
        let dates = [day(0), day(-1), day(-2), day(-4)]
        #expect(StatsAggregator.streak(reviewDates: dates, now: now, calendar: calendar) == 3)
        // No review today but yesterday+before → still counts (grace until midnight).
        #expect(StatsAggregator.streak(reviewDates: [day(-1), day(-2)], now: now, calendar: calendar) == 2)
        // Last review two days ago → broken.
        #expect(StatsAggregator.streak(reviewDates: [day(-2)], now: now, calendar: calendar) == 0)
    }

    @Test("Maturity buckets by state and stability, all buckets present")
    func maturity() {
        let states: [(state: LearningState, stability: Double)] = [
            (.new, 0), (.learning, 1), (.relearning, 2),
            (.review, 5), (.review, 30), (.review, 21),
        ]
        let buckets = StatsAggregator.maturity(states)
        func count(_ b: MaturityBucket) -> Int { buckets.first { $0.bucket == b }!.count }
        #expect(buckets.count == 4)                 // always all four
        #expect(count(.new) == 1)
        #expect(count(.learning) == 2)              // learning + relearning
        #expect(count(.young) == 1)                 // stability 5 < 21
        #expect(count(.mature) == 2)                // 30 and 21 (>= threshold)
    }

    @Test("Forgetting curve is non-empty, starts high, and decreases over time")
    func forgettingCurve() {
        let memories: [(stability: Double, elapsedDays: Double)] = [(10, 0), (30, 5)]
        let curve = StatsAggregator.forgettingCurve(memories, overDays: 20)
        #expect(curve.count == 21)
        #expect(curve.first!.recall > curve.last!.recall)   // decays
        #expect(curve.first!.recall <= 1.0 && curve.last!.recall >= 0)
        // No memory yet → empty curve.
        #expect(StatsAggregator.forgettingCurve([(0, 0)], overDays: 10).isEmpty)
    }

    @Test("At-risk counts memories dropping below the recall threshold")
    func atRisk() {
        // A low-stability word decays fast; a high-stability one stays strong.
        let memories: [(stability: Double, elapsedDays: Double)] = [(1, 0), (500, 0)]
        #expect(StatsAggregator.atRisk(memories, threshold: 0.9, within: 7) == 1)
    }
}
