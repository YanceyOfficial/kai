# Toast Feedback + Diagnostics (Logging)

Date: 2026-07-03
Status: Draft (awaiting review)
Feature branch: `feature/native-english-mvp`

## Goal

Two related pieces of user-facing robustness:

1. **Toast feedback** — an app-wide way to confirm actions (word added, note added/deleted,
   word deleted) and surface failures, with distinct success and error styles.
2. **Error / log collection** — capture the app's logs (which already flow through a
   `LogSink`) into a store that survives restarts, and view / filter / export them from a
   **Diagnostics** screen in Settings.

## Existing building blocks

- `KaiServices.AppLogger` (struct facade) writes to an injectable `LogSink`; `OSLogSink`
  is the production sink. Call sites currently do `AppLogger(sink: OSLogSink())` ad hoc
  (`ReviewStore`, `QuizStore`).
- `KaiUI.KaiToast` + `View.kaiToast(_:isPresented:)` — a per-view ink pill with a
  `Bool` binding, used for "deck complete".

## Design

### 1. Log collection (KaiServices)

**`LogRecord`** — a value type describing one captured log line:

```swift
public struct LogRecord: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var timestamp: Date
    public var level: LogLevel
    public var category: String
    public var message: String
}
```

`LogLevel` gains `Codable` + a short `label` ("DEBUG"/"WARN"/…) for display/export.

**`LogCollector`** — a shared, thread-safe `LogSink` that both buffers in memory and
persists to disk:

- `final class LogCollector: LogSink, @unchecked Sendable`, guarded by an `NSLock`.
- In-memory ring buffer of the last `capacity` (default 1000) `LogRecord`s — the source of
  truth for the viewer.
- Mirrors to a capped **rolling file** (line-delimited JSON) in Application Support
  (`Kai/diagnostics.log`). Behavior: on init, load the file into the ring (keeping the last
  `capacity`); on `write`, append the record and, when the file grows past `2 × capacity`
  lines, rewrite it from the trimmed ring. This bounds file size without per-write rewrites.
- API: `snapshot(minLevel:) -> [LogRecord]` (newest-first), `clear()` (empties ring + file),
  `exportText() -> String` (formatted lines for Share).
- `static let shared = LogCollector()`. A designated init takes the directory URL so tests
  can use a temp dir.

**`FanoutLogSink`** — `LogSink` that forwards `write` to an ordered list of sinks. Production
composition: `FanoutLogSink([OSLogSink(), LogCollector.shared])`.

**`AppLog`** — a shared facade so call sites stop constructing sinks:

```swift
public enum AppLog {
    public static let shared = AppLogger(sink: FanoutLogSink([OSLogSink(), LogCollector.shared]))
}
```

`ReviewStore` / `QuizStore` (and future call sites) use `AppLog.shared` instead of
`AppLogger(sink: OSLogSink())`, so all logs are collected.

### 2. App-wide toasts (KaiUI + app)

**`KaiUI`** — extend the toast with a style:

```swift
public enum KaiToastStyle { case success, error }
```

`KaiToast` renders `success` as the current ink pill with a `checkmark` glyph, and `error`
as a red pill (new `KaiColor.danger`) with an `exclamationmark.triangle` glyph.

**App** — `ToastCenter` drives a single root overlay:

```swift
@MainActor @Observable final class ToastCenter {
    struct Item: Identifiable { let id = UUID(); let message: String; let style: KaiToastStyle }
    private(set) var current: Item?
    func show(_ message: String)   // success/info
    func error(_ message: String)  // error style; also AppLog.shared.error(...)
}
```

- Injected via `@Environment` at the app root; the root view (`MainTabView` host) carries the
  overlay that renders `current` and auto-dismisses (reusing the existing spring/timing).
- `error(_:)` additionally logs through `AppLog.shared` (category `"ui"`), so every failure
  the user sees is also captured for Diagnostics.

**Wired actions** (kept tasteful — confirmations and failures only):

| Action | Toast |
|--------|-------|
| Add words (manual/paste) | `show("Added N words")` |
| AI generation succeeds / fails | `show("Added N words")` / `error("Generation failed: …")` |
| Add annotation | `show("Note added")` |
| Delete annotation | `show("Note deleted")` |
| Delete word (swipe) | `show("Deleted ‘lemma’")` |
| Review/quiz persistence failure | `error("Couldn't save — see Diagnostics")` |

### 3. Diagnostics screen (Settings)

- A new **Diagnostics** section in `SettingsView` with a `NavigationLink` to `LogsView`.
- `LogsView`: reads `LogCollector.shared.snapshot()` (pull on appear + manual refresh),
  newest-first. A segmented **All / Warnings / Errors** filter (maps to `minLevel`). Each row
  shows time, a colored level badge, category, and message.
- Toolbar: **Share** (`ShareLink` over `exportText()`) and **Clear** (confirmation dialog →
  `LogCollector.shared.clear()`).

## Testing

- **KaiServices** (`swift test`): `LogCollector` writes → `snapshot` returns capped,
  newest-first; `clear()` empties; `exportText()` contains the messages; persistence —
  a collector pointed at a temp dir reloads its records after re-init. `FanoutLogSink`
  forwards to all sinks (assert via a capturing test sink).
- **App suite** (simulator): a `ToastCenter` unit test — `show`/`error` set `current` with the
  right style and `error` logs a record.
- Full app suite + KaiCore (simulator) + KaiAI/KaiFSRS/KaiServices stay green.

## Non-goals

- Remote/crash reporting or analytics upload (local only).
- Auto-toasting every log line (toasts are explicit at action sites; the collector captures
  everything for the viewer).
- Redacting secrets — the code already never logs API keys; no new redaction layer.

## Open questions

None outstanding.
