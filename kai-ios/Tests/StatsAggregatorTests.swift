import Testing
import Foundation
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
}
