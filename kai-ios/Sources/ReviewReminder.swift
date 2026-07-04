import Foundation
import KaiServices

/// Orchestrates the daily review reminder from the app's settings + deck state, so the
/// scheduling rule lives in one testable place.
enum ReviewReminder {
    /// Only remind when the user opted in AND there are words to review.
    static func shouldSchedule(enabled: Bool, hasWords: Bool) -> Bool {
        enabled && hasWords
    }

    /// Applies the current settings: schedules the daily reminder, or cancels it.
    static func apply(
        enabled: Bool,
        minutes: Int,
        hasWords: Bool,
        scheduler: DailyReminderScheduling = UNDailyReminderScheduler()
    ) async {
        do {
            if shouldSchedule(enabled: enabled, hasWords: hasWords) {
                try await scheduler.scheduleDaily(hour: minutes / 60, minute: minutes % 60)
            } else {
                try await scheduler.cancel()
            }
        } catch {
            AppLog.shared.error("Reminder scheduling failed: \(error.localizedDescription)", category: "reminder")
        }
    }
}
