# Home-screen Review Widget

Date: 2026-07-04
Status: Draft (awaiting review)
Feature branch: `feature/native-english-mvp`

## Goal

A home-screen widget showing "N words due" (tap → opens the app), to pull the learner back
daily. A widget process can't read the app's SwiftData store, so the app publishes a tiny
snapshot to a shared App Group container that the widget reads.

## Design

### Shared snapshot (KaiServices + App Group)

- **App Group** `group.dev.tuist.kai-ios`, entitled on both the app and widget targets.
- `ReviewWidgetSnapshot` (Codable, in KaiServices): `{ dueCount: Int, totalWords: Int,
  updatedAt: Date }`.
- `WidgetSnapshotStore`: `read() -> ReviewWidgetSnapshot?` / `write(_:)` via
  `UserDefaults(suiteName: appGroupID)` (JSON under one key). `appGroupID` is a constant.

### App — publishing

- `WidgetSync.update(repository:)`: compute `dueCount` (due entries) + `totalWords`, write the
  snapshot, and `WidgetCenter.shared.reloadAllTimelines()`. Called:
  - on launch (`RootView`),
  - after a review session finishes,
  - after adding/deleting words.

### Widget target `KaiWidget`

- `.appExtension` (WidgetKit + SwiftUI), deployment iOS 17, bundle `dev.tuist.kai-ios.widget`.
- `TimelineProvider` reads `WidgetSnapshotStore.read()`; one entry now + a periodic refresh
  (the app also force-reloads on change).
- Views (small + medium): a vermilion hero number `N`, "words due" / "all caught up", on the
  card surface — reusing `KaiColor`/`KaiFont` from KaiUI. Tapping opens the app (default).

### Tuist (`Project.swift`)

- Add the `KaiWidget` target; add `com.apple.security.application-groups = [group.dev.tuist.kai-ios]`
  entitlements to the app and the widget; make the app depend on (embed) `KaiWidget`.

## Testing

- **KaiServices** (`swift test`): `WidgetSnapshotStore` round-trips a snapshot through an
  injected `UserDefaults` suite.
- Widget views + `TimelineProvider` are compiled, verified by running the widget on the
  simulator.

## Non-goals / risks

- **Provisioning:** App Groups should work on a personal team + simulator; if the entitlement
  can't be satisfied, the widget falls back to a static "Open Kai to review" (no live count),
  and the feature is revisited with the paid account.
- No Lock Screen / StandBy / interactive (App Intent) widgets yet — a tap-to-open static
  widget first.
- No live streak/curve on the widget yet (due count only).
