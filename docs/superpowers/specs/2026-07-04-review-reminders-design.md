# Daily Review Reminder

Date: 2026-07-04
Status: Draft (awaiting review)
Feature branch: `feature/native-english-mvp`

## Goal

Bring users back daily — the missing half of spaced repetition. A single, friendly local
notification each day at a time the user picks, fired only when there are words to study.
(Chosen over per-word forgetting pushes and a coalesced digest for the least-annoying,
most habit-forming UX.)

## Design

### KaiServices — daily reminder scheduling

A thin platform adapter behind a protocol (matches the existing notification pattern):

```swift
public protocol DailyReminderScheduling: Sendable {
    func requestAuthorization() async -> Bool          // grant state after the ask
    func isAuthorized() async -> Bool
    func scheduleDaily(hour: Int, minute: Int) async throws
    func cancel() async throws
}
```

**`UNDailyReminderScheduler`** backs it with `UNUserNotificationCenter`:
- `requestAuthorization` → `center.requestAuthorization([.alert, .sound, .badge])`.
- `scheduleDaily` → cancel the existing reminder, then add a `UNCalendarNotificationTrigger`
  (hour/minute, `repeats: true`) under the fixed id `kai.daily-reminder`, with content
  Title "Time to review", Body "Keep your words fresh — a quick review now."
- `cancel` → remove the pending request with that id.

Compiled but not unit-tested (per the "protocol + pure logic + thin adapter" convention).

### App — wiring

- **`ReviewReminder`** (app helper): owns the schedule/cancel decision.
  - Pure rule: `shouldSchedule(enabled:hasWords:) -> Bool` = `enabled && hasWords` (unit-tested).
  - `apply(enabled:minutes:hasWords:)` async: if `shouldSchedule`, `scheduleDaily(hour:minute:)`;
    else `cancel()`. Uses `UNDailyReminderScheduler`.
- **Settings → "Reminders" section**:
  - `Toggle("Daily review reminder", isOn:)` bound to `@AppStorage("reminderEnabled")`.
  - When on: a `DatePicker(.hourAndMinute)` bound to `@AppStorage("reminderMinutes")`
    (Int minutes-since-midnight, default 540 = 09:00) via a `Date` conversion.
  - Enabling requests authorization; if **denied**, revert the toggle and toast
    "Allow notifications in iOS Settings to get reminders."
  - Any change re-applies `ReviewReminder` (with the current deck word count).
- **App root (`RootView`)**: on launch, re-apply `ReviewReminder` with the current settings +
  deck state, so an emptied/filled deck keeps the reminder in sync.

### Data / persistence

`@AppStorage`: `reminderEnabled: Bool = false`, `reminderMinutes: Int = 540`. No new model.

## Testing

- **App suite**: `ReviewReminder.shouldSchedule(enabled:hasWords:)` truth table.
- `UNDailyReminderScheduler` and the Settings UI are compiled, not unit-tested.
- Manual: enable → grant → confirm a pending daily notification (and that changing the time
  reschedules; disabling cancels).

## Non-goals

- Per-word / Ebbinghaus-timed pushes (the built `ForgettingScheduler` stays available for a
  future "smart timing" option, but isn't used here).
- A dynamic due-count in the notification body (a repeating notification has static text;
  computing the live count needs background refresh — out of scope).
- Multiple reminders per day.

## Open questions

None outstanding.
