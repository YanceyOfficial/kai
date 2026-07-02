import Foundation
import Testing
@testable import KaiServices

private let day: TimeInterval = 86_400

@Test("Fire date is lastReview plus the days until retrievability hits the threshold")
func fireDateFromStability() {
    let scheduler = ForgettingScheduler(retentionThreshold: 0.9)
    let base = Date(timeIntervalSince1970: 1_000_000)
    // At threshold 0.9, days-until equals round(stability) (FSRS interval at 0.9).
    let item = ReviewableItem(id: UUID(), stability: 14.0, lastReview: base)
    let reminders = scheduler.reminders(for: [item], now: base)
    #expect(reminders.count == 1)
    #expect(abs(reminders[0].fireDate.timeIntervalSince1970 - (base.timeIntervalSince1970 + 14 * day)) < 1.0)
}

@Test("New items (never reviewed) produce no forgetting reminder")
func newItemsExcluded() {
    let scheduler = ForgettingScheduler()
    let item = ReviewableItem(id: UUID(), stability: 0, lastReview: nil)
    #expect(scheduler.reminders(for: [item], now: Date()).isEmpty)
}

@Test("An already-overdue item fires now, and results are sorted by fire date")
func overdueFiresNowSorted() {
    let scheduler = ForgettingScheduler(retentionThreshold: 0.9)
    let now = Date(timeIntervalSince1970: 2_000_000)
    let overdue = ReviewableItem(id: UUID(), stability: 5, lastReview: now.addingTimeInterval(-100 * day))
    let future = ReviewableItem(id: UUID(), stability: 50, lastReview: now)
    let reminders = scheduler.reminders(for: [overdue, future], now: now)
    #expect(reminders.count == 2)
    #expect(reminders[0].id == overdue.id)              // sorted: overdue (now) first
    #expect(reminders[0].fireDate == now)
    #expect(reminders[1].fireDate > now)
}
