import Foundation

/// Orchestrates the forgetting push: compute reminders, apply quiet hours, replace schedule.
public struct ForgettingPushCoordinator: Sendable {
    private let scheduler: ForgettingScheduler
    private let quietHours: QuietHours?
    private let sink: NotificationScheduling
    private let calendar: Calendar

    public init(scheduler: ForgettingScheduler, quietHours: QuietHours?, sink: NotificationScheduling, calendar: Calendar = .current) {
        self.scheduler = scheduler
        self.quietHours = quietHours
        self.sink = sink
        self.calendar = calendar
    }

    /// Recomputes and re-schedules all forgetting reminders for the given items.
    public func refresh(items: [ReviewableItem], now: Date) async throws {
        try await sink.cancelAll()
        var reminders = scheduler.reminders(for: items, now: now)
        if let quietHours {
            reminders = reminders.map {
                ForgettingReminder(id: $0.id, fireDate: quietHours.adjusted($0.fireDate, calendar: calendar))
            }
        }
        // iOS keeps only the 64 soonest pending local notifications; keep those.
        let capped = Array(reminders.sorted { $0.fireDate < $1.fireDate }.prefix(64))
        try await sink.schedule(capped)
    }
}
