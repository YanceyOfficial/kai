# KaiServices Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement KaiServices — the device-services layer: structured logging, secure API-key storage (Keychain), FSRS-driven forgetting-push scheduling (with quiet hours), and Vision OCR word extraction — each split into pure, unit-tested logic behind a protocol, plus a thin platform adapter.

**Architecture:** KaiServices depends only on KaiFSRS (pure math, no SwiftData), so the whole package builds and tests via `swift test` on macOS. Each capability is a protocol + a pure component (fully tested with stubs) + a thin platform adapter (`OSLogSink`, `KeychainSecretStore`, `UNNotificationScheduler`, `VisionTextRecognizer`) that only needs to compile — the app wires the real adapters at runtime. The valuable, error-prone logic (forgetting-push timing, quiet-hours shifting, OCR candidate filtering) lives in the pure components and is TDD'd.

**Tech Stack:** Swift 6.3, Swift Package Manager, `Foundation`, `os` (Logger), `Security` (Keychain), `UserNotifications`, `Vision`. Depends on the local `KaiFSRS` package. Swift Testing.

## Global Constraints

- Swift toolchain 6.3.x. Platforms: `.macOS(.v14)`, `.iOS(.v17)`.
- **All code comments and user-facing text in English.** Test functions self-document via `@Test("English description")`.
- Test framework: **Swift Testing**. Canonical command: `swift test --package-path Packages/KaiServices` (pure logic + protocol stubs — no SwiftData, no simulator, no real Keychain/Vision/UN calls in tests).
- **Never instantiate platform singletons in tests** (`UNUserNotificationCenter.current()`, real Keychain, `VNRecognizeTextRequest`). Tests use the in-memory / recording / stub implementations. Platform adapters must compile but are exercised only at app runtime.
- KaiServices depends on **KaiFSRS only** (not KaiCore). Inputs are plain value DTOs; mapping from KaiCore models happens in the app layer.
- API keys and secrets are never logged. `AppLogger` must not receive secret values.
- Working branch: `feature/native-english-mvp`. One commit per task.

---

### Task 1: Package scaffold + structured logging

**Files:**
- Create: `Packages/KaiServices/Package.swift`
- Create: `Packages/KaiServices/Sources/KaiServices/AppLogger.swift`
- Test: `Packages/KaiServices/Tests/KaiServicesTests/AppLoggerTests.swift`

**Interfaces:**
- Produces:
  - `KaiServices` library.
  - `enum LogLevel: Int, Comparable, Sendable { case debug, info, warning, error }`
  - `protocol LogSink: Sendable { func write(_ level: LogLevel, category: String, message: String) }`
  - `struct OSLogSink: LogSink` (backed by `os.Logger`, subsystem-scoped).
  - `struct AppLogger: Sendable { init(sink: LogSink, minimumLevel: LogLevel); func debug/info/warning/error(_ message: String, category: String) }` — drops messages below `minimumLevel`.

- [ ] **Step 1: Write Package.swift**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiServices",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KaiServices", targets: ["KaiServices"])
    ],
    dependencies: [
        .package(path: "../KaiFSRS")
    ],
    targets: [
        .target(name: "KaiServices", dependencies: ["KaiFSRS"]),
        .testTarget(name: "KaiServicesTests", dependencies: ["KaiServices"])
    ]
)
```

- [ ] **Step 2: Write the failing test**

`AppLoggerTests.swift`:

```swift
import Testing
@testable import KaiServices

/// Captures log records for assertions.
private final class CapturingSink: LogSink, @unchecked Sendable {
    private(set) var records: [(LogLevel, String, String)] = []
    func write(_ level: LogLevel, category: String, message: String) {
        records.append((level, category, message))
    }
}

@Test("Logger forwards records at or above the minimum level")
func loggerRespectsMinimumLevel() {
    let sink = CapturingSink()
    let logger = AppLogger(sink: sink, minimumLevel: .info)
    logger.debug("dropped", category: "test")
    logger.info("kept", category: "net")
    logger.error("kept2", category: "net")
    #expect(sink.records.count == 2)
    #expect(sink.records[0].0 == .info)
    #expect(sink.records[0].2 == "kept")
    #expect(sink.records[1].0 == .error)
}

@Test("Log levels order debug < info < warning < error")
func logLevelOrder() {
    #expect(LogLevel.debug < LogLevel.info)
    #expect(LogLevel.warning < LogLevel.error)
}
```

- [ ] **Step 3: Run test, verify it fails**

Run: `swift test --package-path Packages/KaiServices`
Expected: FAIL — types not found.

- [ ] **Step 4: Write the implementation**

`AppLogger.swift`:

```swift
import Foundation
import os

/// Severity level for a log record.
public enum LogLevel: Int, Comparable, Sendable {
    case debug, info, warning, error
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A destination for log records. Injectable so tests can capture output.
public protocol LogSink: Sendable {
    func write(_ level: LogLevel, category: String, message: String)
}

/// Production sink backed by the unified logging system (`os.Logger`).
public struct OSLogSink: LogSink {
    private let subsystem: String
    public init(subsystem: String = "app.yancey.kai") { self.subsystem = subsystem }

    public func write(_ level: LogLevel, category: String, message: String) {
        let logger = Logger(subsystem: subsystem, category: category)
        switch level {
        case .debug: logger.debug("\(message, privacy: .public)")
        case .info: logger.info("\(message, privacy: .public)")
        case .warning: logger.warning("\(message, privacy: .public)")
        case .error: logger.error("\(message, privacy: .public)")
        }
    }
}

/// The app's logging facade. Filters by minimum level, then forwards to a sink.
public struct AppLogger: Sendable {
    private let sink: LogSink
    private let minimumLevel: LogLevel

    public init(sink: LogSink, minimumLevel: LogLevel = .debug) {
        self.sink = sink
        self.minimumLevel = minimumLevel
    }

    private func log(_ level: LogLevel, _ message: String, _ category: String) {
        guard level >= minimumLevel else { return }
        sink.write(level, category: category, message: message)
    }

    public func debug(_ message: String, category: String) { log(.debug, message, category) }
    public func info(_ message: String, category: String) { log(.info, message, category) }
    public func warning(_ message: String, category: String) { log(.warning, message, category) }
    public func error(_ message: String, category: String) { log(.error, message, category) }
}
```

- [ ] **Step 5: Run test, verify it passes**

Run: `swift test --package-path Packages/KaiServices`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Packages/KaiServices
git commit -m "feat(KaiServices): package scaffold and structured logging"
```

---

### Task 2: Secret store (protocol + in-memory + Keychain adapter)

**Files:**
- Create: `Packages/KaiServices/Sources/KaiServices/SecretStore.swift`
- Create: `Packages/KaiServices/Sources/KaiServices/KeychainSecretStore.swift`
- Test: `Packages/KaiServices/Tests/KaiServicesTests/SecretStoreTests.swift`

**Interfaces:**
- Produces:
  - `enum SecretStoreError: Error, Equatable, Sendable { case unexpectedStatus(Int32) }`
  - `protocol SecretStore: Sendable { func set(_ value: String, for key: String) throws; func string(for key: String) throws -> String?; func removeValue(for key: String) throws }`
  - `final class InMemorySecretStore: SecretStore` (thread-safe via a lock) — for tests and previews.
  - `struct KeychainSecretStore: SecretStore` (Security framework, `kSecClassGenericPassword`, scoped by `service`) — production; compiled, not unit-tested here.

- [ ] **Step 1: Write the failing test**

`SecretStoreTests.swift`:

```swift
import Testing
@testable import KaiServices

@Test("In-memory secret store round-trips, overwrites, and deletes")
func inMemoryRoundTrip() throws {
    let store = InMemorySecretStore()
    #expect(try store.string(for: "claudeKey") == nil)
    try store.set("sk-1", for: "claudeKey")
    #expect(try store.string(for: "claudeKey") == "sk-1")
    try store.set("sk-2", for: "claudeKey")           // overwrite
    #expect(try store.string(for: "claudeKey") == "sk-2")
    try store.removeValue(for: "claudeKey")
    #expect(try store.string(for: "claudeKey") == nil)
}

@Test("Deleting a missing key is a no-op")
func deleteMissingKey() throws {
    let store = InMemorySecretStore()
    try store.removeValue(for: "absent")               // must not throw
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `swift test --package-path Packages/KaiServices`
Expected: FAIL — types not found.

- [ ] **Step 3: Write the implementation**

`SecretStore.swift`:

```swift
import Foundation

/// Errors from the secret store.
public enum SecretStoreError: Error, Equatable, Sendable {
    /// An unexpected OSStatus from the Keychain.
    case unexpectedStatus(Int32)
}

/// A secure key/value store for secrets such as API keys.
public protocol SecretStore: Sendable {
    func set(_ value: String, for key: String) throws
    func string(for key: String) throws -> String?
    func removeValue(for key: String) throws
}

/// In-memory secret store for tests and SwiftUI previews. Thread-safe.
public final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private var storage: [String: String] = [:]
    private let lock = NSLock()

    public init() {}

    public func set(_ value: String, for key: String) throws {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }

    public func string(for key: String) throws -> String? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    public func removeValue(for key: String) throws {
        lock.lock(); defer { lock.unlock() }
        storage[key] = nil
    }
}
```

`KeychainSecretStore.swift`:

```swift
import Foundation
import Security

/// Production secret store backed by the Keychain (generic password items).
/// Compiled for the app; exercised at runtime, not in unit tests.
public struct KeychainSecretStore: SecretStore {
    private let service: String
    public init(service: String = "app.yancey.kai.secrets") { self.service = service }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    public func set(_ value: String, for key: String) throws {
        let data = Data(value.utf8)
        // Delete any existing item, then add fresh (upsert).
        SecItemDelete(baseQuery(for: key) as CFDictionary)
        var attributes = baseQuery(for: key)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw SecretStoreError.unexpectedStatus(status) }
    }

    public func string(for key: String) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw SecretStoreError.unexpectedStatus(status) }
        guard let data = result as? Data else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    public func removeValue(for key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretStoreError.unexpectedStatus(status)
        }
    }
}
```

- [ ] **Step 4: Run test, verify it passes**

Run: `swift test --package-path Packages/KaiServices`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/KaiServices
git commit -m "feat(KaiServices): secret store with Keychain adapter"
```

---

### Task 3: Forgetting-push scheduler (FSRS-driven fire dates)

Compute, for each reviewable item, the moment its recall probability drops to the retention threshold — reusing KaiFSRS. This is the core of the Ebbinghaus push.

**Files:**
- Create: `Packages/KaiServices/Sources/KaiServices/ReviewableItem.swift`
- Create: `Packages/KaiServices/Sources/KaiServices/ForgettingScheduler.swift`
- Test: `Packages/KaiServices/Tests/KaiServicesTests/ForgettingSchedulerTests.swift`

**Interfaces:**
- Consumes: `KaiFSRS.FSRSScheduler`, `FSRSParameters`.
- Produces:
  - `struct ReviewableItem: Equatable, Sendable { let id: UUID; let stability: Double; let lastReview: Date? }`
  - `struct ForgettingReminder: Equatable, Sendable { let id: UUID; let fireDate: Date }`
  - `struct ForgettingScheduler: Sendable { init(parameters: FSRSParameters = .fsrs6Default, retentionThreshold: Double = 0.9); func reminders(for items: [ReviewableItem], now: Date) -> [ForgettingReminder] }` — items with `lastReview == nil` (new, never reviewed) are excluded; fire date is `lastReview + daysUntil(threshold)`, clamped so an already-overdue item fires at `now`. Result sorted by `fireDate`.

- [ ] **Step 1: Write the failing test**

`ForgettingSchedulerTests.swift`:

```swift
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
```

- [ ] **Step 2: Run test, verify it fails**

Run: `swift test --package-path Packages/KaiServices`
Expected: FAIL — types not found.

- [ ] **Step 3: Write the implementation**

`ReviewableItem.swift`:

```swift
import Foundation

/// The minimal per-item state the forgetting scheduler needs. The app maps
/// KaiCore entries to this DTO so KaiServices stays free of SwiftData.
public struct ReviewableItem: Equatable, Sendable {
    public let id: UUID
    public let stability: Double
    public let lastReview: Date?
    public init(id: UUID, stability: Double, lastReview: Date?) {
        self.id = id
        self.stability = stability
        self.lastReview = lastReview
    }
}

/// A scheduled forgetting reminder for one item.
public struct ForgettingReminder: Equatable, Sendable {
    public let id: UUID
    public let fireDate: Date
    public init(id: UUID, fireDate: Date) {
        self.id = id
        self.fireDate = fireDate
    }
}
```

`ForgettingScheduler.swift`:

```swift
import Foundation
import KaiFSRS

/// Computes when to remind the learner about each item, using FSRS to find the
/// moment recall probability falls to the retention threshold (the Ebbinghaus point).
public struct ForgettingScheduler: Sendable {
    private let scheduler: FSRSScheduler

    /// - Parameter retentionThreshold: recall probability at which to remind (e.g. 0.9).
    public init(parameters: FSRSParameters = .fsrs6Default, retentionThreshold: Double = 0.9) {
        // Reuse FSRS's interval math: nextInterval at requestRetention == threshold
        // is exactly the number of days until retrievability decays to that threshold.
        self.scheduler = FSRSScheduler(parameters: parameters, requestRetention: retentionThreshold)
    }

    public func reminders(for items: [ReviewableItem], now: Date) -> [ForgettingReminder] {
        let secondsPerDay: TimeInterval = 86_400
        var result: [ForgettingReminder] = []
        for item in items {
            guard let lastReview = item.lastReview, item.stability > 0 else { continue }
            let days = scheduler.nextInterval(stability: item.stability)
            let due = lastReview.addingTimeInterval(Double(days) * secondsPerDay)
            let fireDate = max(due, now)   // never schedule in the past
            result.append(ForgettingReminder(id: item.id, fireDate: fireDate))
        }
        return result.sorted { $0.fireDate < $1.fireDate }
    }
}
```

- [ ] **Step 4: Run test, verify it passes**

Run: `swift test --package-path Packages/KaiServices`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/KaiServices
git commit -m "feat(KaiServices): FSRS-driven forgetting scheduler"
```

---

### Task 4: Quiet hours

Shift a reminder's fire date out of a do-not-disturb window into the next allowed time.

**Files:**
- Create: `Packages/KaiServices/Sources/KaiServices/QuietHours.swift`
- Test: `Packages/KaiServices/Tests/KaiServicesTests/QuietHoursTests.swift`

**Interfaces:**
- Produces:
  - `struct QuietHours: Sendable { let startHour: Int; let endHour: Int; init(startHour: Int, endHour: Int) }` — a daily window `[startHour, endHour)` in a given calendar; supports windows that wrap midnight (e.g. 22→7).
  - `func adjusted(_ date: Date, calendar: Calendar) -> Date` — if `date` falls inside the window, returns the window's end time; otherwise returns `date` unchanged.

- [ ] **Step 1: Write the failing test**

`QuietHoursTests.swift`:

```swift
import Foundation
import Testing
@testable import KaiServices

private func utcCalendar() -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int) -> Date {
    let c = utcCalendar()
    return c.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

@Test("A time inside a midnight-wrapping quiet window is pushed to the window end")
func wrappingWindowShift() {
    let qh = QuietHours(startHour: 22, endHour: 7)   // 22:00–07:00
    let cal = utcCalendar()
    // 02:00 is inside the window -> shifted to 07:00 the same morning.
    let shifted = qh.adjusted(date(2026, 1, 2, 2), calendar: cal)
    #expect(shifted == date(2026, 1, 2, 7))
    // 23:00 is inside the window -> shifted to 07:00 the NEXT morning.
    let shiftedLate = qh.adjusted(date(2026, 1, 2, 23), calendar: cal)
    #expect(shiftedLate == date(2026, 1, 3, 7))
}

@Test("A time outside the quiet window is unchanged")
func outsideWindowUnchanged() {
    let qh = QuietHours(startHour: 22, endHour: 7)
    let cal = utcCalendar()
    let noon = date(2026, 1, 2, 12)
    #expect(qh.adjusted(noon, calendar: cal) == noon)
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `swift test --package-path Packages/KaiServices`
Expected: FAIL — `QuietHours` not found.

- [ ] **Step 3: Write the implementation**

`QuietHours.swift`:

```swift
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
```

- [ ] **Step 4: Run test, verify it passes**

Run: `swift test --package-path Packages/KaiServices`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/KaiServices
git commit -m "feat(KaiServices): quiet-hours adjustment"
```

---

### Task 5: Notification scheduling (coordinator + protocol + adapter)

A coordinator turns items into quiet-hours-adjusted reminders and hands them to a `NotificationScheduling` sink. The real `UNNotificationScheduler` adapter is compiled but tested via a recording stub.

**Files:**
- Create: `Packages/KaiServices/Sources/KaiServices/NotificationScheduling.swift`
- Create: `Packages/KaiServices/Sources/KaiServices/UNNotificationScheduler.swift`
- Create: `Packages/KaiServices/Sources/KaiServices/ForgettingPushCoordinator.swift`
- Test: `Packages/KaiServices/Tests/KaiServicesTests/ForgettingPushCoordinatorTests.swift`

**Interfaces:**
- Produces:
  - `protocol NotificationScheduling: Sendable { func schedule(_ reminders: [ForgettingReminder]) async throws; func cancelAll() async throws }`
  - `final class UNNotificationScheduler: NotificationScheduling` — converts reminders to `UNTimeIntervalNotificationTrigger` + `UNMutableNotificationContent` on `UNUserNotificationCenter.current()`. Compiled, not unit-tested.
  - `struct ForgettingPushCoordinator: Sendable { init(scheduler: ForgettingScheduler, quietHours: QuietHours?, sink: NotificationScheduling); func refresh(items: [ReviewableItem], now: Date) async throws }` — computes reminders, applies quiet hours, replaces existing schedule.

- [ ] **Step 1: Write the failing test**

`ForgettingPushCoordinatorTests.swift`:

```swift
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
    let coord = ForgettingPushCoordinator(
        scheduler: ForgettingScheduler(retentionThreshold: 0.9),
        quietHours: qh,
        sink: sink
    )
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
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
```

- [ ] **Step 2: Run test, verify it fails**

Run: `swift test --package-path Packages/KaiServices`
Expected: FAIL — types not found.

- [ ] **Step 3: Write the implementation**

`NotificationScheduling.swift`:

```swift
import Foundation

/// A sink that schedules (and clears) forgetting reminders as local notifications.
public protocol NotificationScheduling: Sendable {
    func schedule(_ reminders: [ForgettingReminder]) async throws
    func cancelAll() async throws
}
```

`UNNotificationScheduler.swift`:

```swift
import Foundation
import UserNotifications

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
```

`ForgettingPushCoordinator.swift`:

```swift
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
        try await sink.schedule(reminders)
    }
}
```

- [ ] **Step 4: Run test, verify it passes**

Run: `swift test --package-path Packages/KaiServices`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/KaiServices
git commit -m "feat(KaiServices): forgetting-push coordinator and notification adapter"
```

---

### Task 6: OCR word extraction (filter + Vision adapter)

Turn recognized text lines into de-duplicated single-word candidates for the OCR ingestion entry point.

**Files:**
- Create: `Packages/KaiServices/Sources/KaiServices/TextRecognizer.swift`
- Create: `Packages/KaiServices/Sources/KaiServices/WordCandidateExtractor.swift`
- Create: `Packages/KaiServices/Sources/KaiServices/VisionTextRecognizer.swift`
- Test: `Packages/KaiServices/Tests/KaiServicesTests/WordCandidateExtractorTests.swift`

**Interfaces:**
- Produces:
  - `protocol TextRecognizer: Sendable { func recognizeLines(in imageData: Data) async throws -> [String] }`
  - `struct WordCandidateExtractor: Sendable { init(minLength: Int = 2); func candidates(from lines: [String]) -> [String] }` — splits lines on whitespace, strips surrounding punctuation, keeps tokens that are purely alphabetic and at least `minLength` long, lowercases, de-duplicates preserving first-seen order.
  - `struct VisionTextRecognizer: TextRecognizer` — runs `VNRecognizeTextRequest` on a decoded image (`.accurate`, language correction on). Compiled, not unit-tested.

- [ ] **Step 1: Write the failing test**

`WordCandidateExtractorTests.swift`:

```swift
import Testing
@testable import KaiServices

@Test("Extractor strips punctuation, drops non-alpha and short tokens, dedupes case-insensitively")
func candidateFiltering() {
    let extractor = WordCandidateExtractor(minLength: 2)
    let lines = ["The eccentric, obsessive genius.", "genius 42 a", "Eccentric!"]
    let out = extractor.candidates(from: lines)
    // "The" -> "the"; "eccentric"; "obsessive"; "genius"; then dupes/short/numeric dropped.
    #expect(out == ["the", "eccentric", "obsessive", "genius"])
}

@Test("Empty and whitespace-only input yields no candidates")
func emptyInput() {
    let extractor = WordCandidateExtractor()
    #expect(extractor.candidates(from: ["", "   ", "!!!"]).isEmpty)
}
```

- [ ] **Step 2: Run test, verify it fails**

Run: `swift test --package-path Packages/KaiServices`
Expected: FAIL — types not found.

- [ ] **Step 3: Write the implementation**

`TextRecognizer.swift`:

```swift
import Foundation

/// Recognizes text lines from an encoded image (PNG/JPEG data).
public protocol TextRecognizer: Sendable {
    func recognizeLines(in imageData: Data) async throws -> [String]
}
```

`WordCandidateExtractor.swift`:

```swift
import Foundation

/// Turns recognized text lines into de-duplicated single-word candidates.
public struct WordCandidateExtractor: Sendable {
    private let minLength: Int
    public init(minLength: Int = 2) { self.minLength = minLength }

    public func candidates(from lines: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for line in lines {
            for rawToken in line.split(whereSeparator: { $0.isWhitespace }) {
                let token = rawToken.trimmingCharacters(in: .punctuationCharacters)
                guard token.count >= minLength, token.allSatisfy({ $0.isLetter }) else { continue }
                let lower = token.lowercased()
                if seen.insert(lower).inserted { result.append(lower) }
            }
        }
        return result
    }
}
```

`VisionTextRecognizer.swift`:

```swift
import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Production text recognizer backed by Vision. Compiled for the app; not unit-tested.
public struct VisionTextRecognizer: TextRecognizer {
    public init() {}

    public func recognizeLines(in imageData: Data) async throws -> [String] {
        guard let cgImage = Self.decode(imageData) else { return [] }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error { continuation.resume(throwing: error); return }
                let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do { try handler.perform([request]) } catch { continuation.resume(throwing: error) }
        }
    }

    private static func decode(_ data: Data) -> CGImage? {
        #if canImport(UIKit)
        return UIImage(data: data)?.cgImage
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else { return nil }
        var rect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
}
```

- [ ] **Step 4: Run test, verify it passes**

Run: `swift test --package-path Packages/KaiServices`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/KaiServices
git commit -m "feat(KaiServices): OCR word-candidate extractor and Vision adapter"
```

---

## Self-Review

**Spec coverage** (design doc §3 KaiServices + §10 notifications):
- Keychain secret storage → Task 2 ✅ (protocol + in-memory + Keychain adapter).
- `os.Logger` structured logging → Task 1 ✅.
- FSRS/Ebbinghaus forgetting push + quiet hours → Tasks 3, 4, 5 ✅ (fire-date math reuses KaiFSRS; quiet-hours shifting; coordinator wiring; UN adapter).
- Vision OCR → Task 6 ✅ (candidate extraction tested; Vision adapter compiled).
- Toast → moved to KaiUI (a later UI plan); it is a SwiftUI overlay, not a device service.
- TTS/audio playback → deferred to the learning-loop UI plan (thin `AVSpeechSynthesizer` wrapper, no logic to unit-test now).

**Placeholder scan:** No TBD/TODO. Platform adapters (`KeychainSecretStore`, `UNNotificationScheduler`, `VisionTextRecognizer`) are complete implementations that are compiled but not unit-tested (their logic-bearing companions are), which the constraints call out explicitly — not placeholders.

**Type consistency:** `SecretStore` methods match across `InMemorySecretStore` and `KeychainSecretStore`; `NotificationScheduling` matches the recording stub and `UNNotificationScheduler`; `ForgettingReminder`/`ReviewableItem` field names are consistent across scheduler, coordinator, and tests; `ForgettingScheduler(retentionThreshold:)` reused in the coordinator matches Task 3.

**Risk / notes:** (1) The forgetting fire-date uses `FSRSScheduler.nextInterval` at `requestRetention == threshold`, which is day-granular (rounded) — appropriate for a daily push. (2) Vision's macOS `NSImage.cgImage` path and the UN/Keychain singletons are only compiled here; their behavior is validated at app runtime, and the pure companions cover the logic that can actually be wrong. (3) Quiet-hours math is the trickiest pure code (midnight wrap) and is directly TDD'd.
```
