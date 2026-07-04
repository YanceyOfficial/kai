import Foundation
#if canImport(UserNotifications)
@preconcurrency import UserNotifications
#endif

/// Schedules a single repeating daily local notification. Injectable so the app logic
/// stays testable; the concrete `UN…` adapter is compiled, not unit-tested.
public protocol DailyReminderScheduling: Sendable {
    /// Prompts for notification permission; returns whether it was granted.
    func requestAuthorization() async -> Bool
    /// Whether notifications are currently authorized.
    func isAuthorized() async -> Bool
    /// Schedules (replacing any existing) a daily reminder at the given wall-clock time.
    func scheduleDaily(hour: Int, minute: Int) async throws
    /// Cancels the daily reminder.
    func cancel() async throws
}

/// Production reminder sink backed by `UNUserNotificationCenter`.
public final class UNDailyReminderScheduler: DailyReminderScheduling {
    private let center: UNUserNotificationCenter
    private let identifier = "kai.daily-reminder"

    public init(center: UNUserNotificationCenter = .current()) { self.center = center }

    public func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
    }

    public func scheduleDaily(hour: Int, minute: Int) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "Time to review"
        content.body = "Keep your words fresh — a quick review now."
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    public func cancel() async throws {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
