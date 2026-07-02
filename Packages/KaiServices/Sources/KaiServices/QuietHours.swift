import Foundation

/// A daily do-not-disturb window `[startHour, endHour)`. Supports windows that
/// wrap past midnight (e.g. 22 → 7). Reminders inside the window are moved to its end.
public struct QuietHours: Sendable {
    public let startHour: Int
    public let endHour: Int
    public init(startHour: Int, endHour: Int) {
        self.startHour = startHour
        self.endHour = endHour
    }

    private var wraps: Bool { startHour >= endHour }

    /// True if `hour` falls within the quiet window.
    private func contains(hour: Int) -> Bool {
        wraps ? (hour >= startHour || hour < endHour) : (hour >= startHour && hour < endHour)
    }

    /// Returns `date` moved to the window's end if it falls inside the window; otherwise `date`.
    public func adjusted(_ date: Date, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: date)
        guard contains(hour: hour) else { return date }
        // The window ends at `endHour`. If the date is in the pre-midnight part of a
        // wrapping window (hour >= startHour), the end is on the following day.
        let endIsNextDay = wraps && hour >= startHour
        let dayStart = calendar.startOfDay(for: date)
        let base = endIsNextDay ? calendar.date(byAdding: .day, value: 1, to: dayStart)! : dayStart
        return calendar.date(byAdding: .hour, value: endHour, to: base)!
    }
}
