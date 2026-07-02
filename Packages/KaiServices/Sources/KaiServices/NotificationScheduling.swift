import Foundation

/// A sink that schedules (and clears) forgetting reminders as local notifications.
public protocol NotificationScheduling: Sendable {
    func schedule(_ reminders: [ForgettingReminder]) async throws
    func cancelAll() async throws
}
