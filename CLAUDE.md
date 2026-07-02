# CLAUDE.md — Kai (甲斐)

Native Apple rewrite of the "Kai" flashcard app for memorizing difficult vocabulary
(English now, Japanese later). SwiftUI + SwiftData + Swift Charts, on-device AI
(Claude/OpenAI), FSRS spaced repetition. iPhone first; Watch/Mac/TV later.

## Layout

- `Project.swift` — **Tuist** manifest. The Xcode project/workspace are generated, not committed.
- `App/` — the app target (`Kai`, bundle `app.yancey.kai`, Swift 6, iOS 17+). `App/Sources`, `App/Tests`.
- `Packages/` — local Swift packages (the kernel; no UI):
  - `KaiCore` — SwiftData models, enums, value types, `VocabularyRepository`. **CloudKit-compatible** modeling (defaults/optionals, no `@Attribute(.unique)`, code-layer dedupe). Sync is off for now.
  - `KaiFSRS` — pure FSRS-6 spaced-repetition algorithm. Zero dependencies. Validated against ts-fsrs.
  - `KaiAI` — `LLMProvider` protocol + Claude/OpenAI structured-output over `URLSession` (`HTTPTransport` is injectable). Produces Codable DTOs, not SwiftData. Depends on KaiCore (enums only).
  - `KaiServices` — logging (`os.Logger`), Keychain (`SecretStore`), FSRS-driven forgetting-push scheduling + quiet hours, Vision OCR. Depends on KaiFSRS. Pattern: **protocol + pure (tested) logic + thin platform adapter (compiled, not unit-tested)**.
- `docs/superpowers/` — design spec (`specs/`) and per-package TDD implementation plans (`plans/`).

## Build / run / test

Requires Xcode 26.x + Tuist. Prefix commands with `export PATH="/opt/homebrew/bin:$PATH"` if needed.

```bash
# Generate the Xcode project (after cloning or editing Project.swift / packages)
tuist generate
# (for VSCode/SourceKit-LSP indexing) regenerate the build-server config afterward:
xcode-build-server config -workspace Kai.xcworkspace -scheme Kai

# Build & run the app in the simulator
xcodebuild build -workspace Kai.xcworkspace -scheme Kai -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Testing rules (important)

- **Pure packages run on macOS via `swift test`** (fast, no simulator):
  ```bash
  swift test --package-path Packages/KaiFSRS
  swift test --package-path Packages/KaiAI
  swift test --package-path Packages/KaiServices
  ```
- **KaiCore (and any SwiftData test) MUST run on the iOS Simulator** — SwiftData `#Predicate`
  fetches SIGTRAP on the macOS test host:
  ```bash
  xcodebuild test -scheme KaiCore -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
  ```
  All SwiftData tests live in ONE `@Suite(.serialized)` sharing a single in-memory
  `ModelContainer` (concurrent container creation crashes SwiftData). See
  `Packages/KaiCore/Tests/KaiCoreTests/SwiftDataTests.swift`.

## Conventions

- **All code comments and user-facing app copy are in English.** (Design/plan docs may be Chinese.)
- **TDD** with **Swift Testing** (`import Testing` / `@Test("English label")` / `#expect`), not XCTest.
- Source/public declarations get English `///` doc comments; test functions self-document via `@Test` labels.
- API keys live in the Keychain (`KaiServices.SecretStore`); never logged, never hardcoded, never committed.
- The AI layer talks to Claude (`claude-opus-4-8` default) and OpenAI via structured outputs;
  models are user-configurable in settings. No official Swift SDK — raw REST over `URLSession`.

## Status (2026-07)

Kernel complete and green: KaiCore (16 tests), KaiFSRS (23), KaiAI (18), KaiServices (13);
Tuist app scaffold builds and launches in the simulator. Next: `KaiUI` (Toast, flip card,
quiz widgets, Swift Charts) and the app's feature screens.
