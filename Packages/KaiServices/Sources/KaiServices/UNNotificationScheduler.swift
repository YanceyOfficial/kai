import Foundation
#if canImport(UserNotifications)
@preconcurrency import UserNotifications
#endif

/// Production notification sink backed by UNUserNotificationCenter.
/// Compiled for the app; exercised at runtime, not in unit tests.
public final class UNNotificationScheduler: NotificationScheduling {
    private let center: UNUserNotificationCenter
    private let identifierPrefix = "kai.forgetting."

    public init(center: UNUserNotificationCenter = .current()) { self.center = center }

    public func schedule(_ reminders: [ForgettingReminder]) async throws {
        let now = Date()
        for reminder in reminders {
            let interval = max(reminder.fireDate.timeIntervalSince(now), 1)
            let content = UNMutableNotificationContent()
            content.title = "Time to review"
            content.body = "A word is about to slip — a quick review keeps it."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: identifierPrefix + reminder.id.uuidString, content: content, trigger: trigger)
            try await center.add(request)
        }
    }

    public func cancelAll() async throws {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
