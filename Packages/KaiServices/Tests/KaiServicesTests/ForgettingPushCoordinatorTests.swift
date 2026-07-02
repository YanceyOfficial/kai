import Foundation
import Testing
@testable import KaiServices

private actor RecordingSink: NotificationScheduling {
    private(set) var scheduled: [ForgettingReminder] = []
    private(set) var cancelCount = 0
    func schedule(_ reminders: [ForgettingReminder]) async throws { scheduled = reminders }
    func cancelAll() async throws { cancelCount += 1 }
    func snapshot() -> ([ForgettingReminder], Int) { (scheduled, cancelCount) }
}

@Test("Coordinator cancels, computes reminders, applies quiet hours, and schedules")
func coordinatorRefresh() async throws {
    let sink = RecordingSink()
    let qh = QuietHours(startHour: 0, endHour: 8)   // early morning is quiet
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
    let coord = ForgettingPushCoordinator(
        scheduler: ForgettingScheduler(retentionThreshold: 0.9),
        quietHours: qh,
        sink: sink,
        calendar: cal
    )
    let lastReview = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 2))! // 02:00
    let item = ReviewableItem(id: UUID(), stability: 1.0, lastReview: lastReview) // ~1 day later, ~02:00 (quiet)
    try await coord.refresh(items: [item], now: lastReview)

    let (scheduled, cancels) = await sink.snapshot()
    #expect(cancels == 1)
    #expect(scheduled.count == 1)
    // The natural fire (~02:00) is inside 00:00–08:00, so it is pushed to 08:00.
    let hour = cal.component(.hour, from: scheduled[0].fireDate)
    #expect(hour == 8)
}

@Test("Coordinator caps scheduled reminders at 64")
func coordinatorCaps64Reminders() async throws {
    let sink = RecordingSink()
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
    let coord = ForgettingPushCoordinator(
        scheduler: ForgettingScheduler(retentionThreshold: 0.9),
        quietHours: nil,
        sink: sink,
        calendar: cal
    )
    let lastReview = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!

    // Create 70 items with the same lastReview but increasing stability to ensure different fire dates.
    var items: [ReviewableItem] = []
    for i in 0..<70 {
        let item = ReviewableItem(id: UUID(), stability: Double(i) * 0.1 + 0.5, lastReview: lastReview)
        items.append(item)
    }

    try await coord.refresh(items: items, now: lastReview)

    let (scheduled, cancels) = await sink.snapshot()
    #expect(cancels == 1)
    #expect(scheduled.count == 64)
}
