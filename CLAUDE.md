# CLAUDE.md — Kai (甲斐)

Native Apple rewrite of the "Kai" flashcard app for memorizing difficult vocabulary,
in English and Japanese (one deck per language, switched in the app). SwiftUI + SwiftData + Swift Charts, on-device AI
(Claude/OpenAI), FSRS spaced repetition. iPhone first; Watch/Mac/TV later.

## Layout

- Organized per the **Tuist standard template** (`tuist init`): `Project.swift` + `Tuist.swift` + `Tuist/Package.swift`. The Xcode project/workspace are generated (`tuist generate`), not committed.
- `kai-ios/` — the app target (`kai-ios`, product module `KaiIos`, bundle `dev.tuist.kai-ios`, Swift 6, iOS 17+). Uses Tuist `buildableFolders`: `kai-ios/Sources` (app code), `kai-ios/Resources` (assets), `kai-ios/Tests`.
- `Packages/` — local Swift packages (the kernel; no UI):
  - `KaiCore` — SwiftData models, enums, value types, `VocabularyRepository`, and `ReviewScheduler` (bridges the persisted `SchedulingState` to KaiFSRS). **CloudKit-compatible** modeling (defaults/optionals, no `@Attribute(.unique)`, code-layer dedupe). Sync is off for now. Depends on KaiFSRS.
  - `KaiFSRS` — pure FSRS-6 spaced-repetition algorithm. Zero dependencies. Validated against ts-fsrs.
  - `KaiAI` — `LLMProvider` protocol + Claude/OpenAI structured-output over `URLSession` (`HTTPTransport` is injectable). Produces Codable DTOs, not SwiftData. Depends on KaiCore (enums only).
  - `KaiServices` — logging (`os.Logger`), Keychain (`SecretStore`), FSRS-driven forgetting-push scheduling + quiet hours, Vision OCR, word pronunciation (`PronunciationVoice`: Youdao dictvoice via `AVPlayer` — English by `type`, Japanese by `le=jap`, said by its kana reading (`JapaneseSpeech`); whatever Youdao has no audio for, e.g. a Japanese sentence or no network, falls back to `AVSpeechSynthesizer`). Depends on KaiFSRS. Pattern: **protocol + pure (tested) logic + thin platform adapter (compiled, not unit-tested)**.
  - `KaiUI` — the design system (`KaiColor`/`KaiFont`/`KaiSpacing`, `KaiMotion` springs + gesture math, `FlipCard`, `KaiMark`, toasts) and ruby: `Ruby` parses the inline furigana markup `{漢字|かんじ}` the AI writes into Japanese sentences (`plain` / `reading`), and `RubyText` shows reading text: a read-only **TextKit 2** `UITextView` (TextKit 1 ignores Core Text ruby), so the system lays out the furigana (overhang, kinsoku) and a long press selects any span for the system edit menu — Copy, Look Up, Translate, Writing Tools. The card back and word detail use it for all their reading text; `showsFurigana` off drops the readings. Tested with `swift test --package-path Packages/KaiUI`.
- `docs/superpowers/` — design spec (`specs/`) and per-package TDD implementation plans (`plans/`).
- App icon: `kai-ios/Resources/AppIcon.icon`, an Icon Composer document (SVG layers + `icon.json`;
  Xcode 26 compiles Liquid Glass for iOS 26+ and flat PNGs for older iOS), plus the launch screen's
  `LaunchMark` (vector SVG) and `LaunchBackground` in `Assets.xcassets`. All generated —
  `swift scripts/generate_app_icon.swift kai-ios/Resources` — never edited by hand.
  The mark is a Tokiwa-green "sliced sun"; `KaiMark` (KaiUI) draws the same geometry in SwiftUI for
  onboarding, the widget and `LaunchSplash` (the launch sunrise, which holds onboarding back until it
  ends), so change the two together.

## Build / run / test

Requires Xcode 26.x + Tuist. Prefix commands with `export PATH="/opt/homebrew/bin:$PATH"` if needed.

```bash
# Generate the Xcode project (after cloning or editing Project.swift / packages)
tuist generate
# (for VSCode/SourceKit-LSP indexing) regenerate the build-server config afterward:
xcode-build-server config -workspace kai-ios.xcworkspace -scheme kai-ios

# Build & run the app in the simulator (product is kai_ios.app, bundle dev.tuist.kai-ios)
xcodebuild build -workspace kai-ios.xcworkspace -scheme kai-ios -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Testing rules (important)

- **Pure packages run on macOS via `swift test`** (fast, no simulator):
  ```bash
  swift test --package-path Packages/KaiFSRS
  swift test --package-path Packages/KaiAI
  swift test --package-path Packages/KaiServices
  ```
- **KaiCore (and any SwiftData test) MUST run on the iOS Simulator** — SwiftData `#Predicate`
  fetches SIGTRAP on the macOS test host. Run from the package directory, using the
  package's own scheme (independent of the Tuist workspace):
  ```bash
  (cd Packages/KaiCore && xcodebuild test -scheme KaiCore -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
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

Kernel green: KaiCore (20 tests), KaiFSRS (23), KaiAI (18), KaiServices (18). App green:
26 tests in `kai-iosTests` (run on the simulator).

The app is a `MainTabView` shell — Review / Quiz / Words / Stats / Settings — over one
SwiftData store (a starter deck per language seeded at launch by `StarterSeed`).
**Languages:** `AppSettings.studyLanguage` (`@AppStorage("studyLanguage")`) picks the deck —
Settings → Language, or the menu under "Kai" on the Review tab. `MainTabView` is keyed by it
(`.id`), so switching rebuilds every tab and each loads its own language's words; stores take
the language in `init` (tests pass it explicitly). Japanese cards reuse the English schema with
per-field meaning set by `PromptBuilder` (phonetic = kana reading + pitch accent `なつかしい ④`,
syllables = morae, roots = kanji breakdown) and ruby markup in every Japanese sentence;
`AICardMapper` strips markup from anything matched or compared (lemma, related words, quiz
answers). Quiz answers are kana-insensitive for Japanese. Neutral palette
with light/dark support (`KaiColor` adaptive) and a Tokiwa green accent (常磐色,
`KaiColor.accent`, #1B813E / #23A750 dark; `vermilion` is a legacy alias of it that app
views drop as they are redesigned). The "Again" rating is red (`KaiColor.danger`).
- **Review** — `ReviewStore.load(newLimit:)` composes a session (up to N new words
  interleaved with due review words via `SessionComposer`); each rating reschedules
  through `ReviewScheduler`/FSRS, persists, and writes a `ReviewLog`. Flip card has
  haptics and auto-playing Youdao pronunciation. Finishing a group offers a chained quiz.
- **Quiz** — single-choice meaning quiz (`QuizGenerator` pure + `QuizStore`) that feeds
  FSRS (correct → good, wrong → again); also reachable as a follow-up to a review group.
- **Words** — searchable list + authoring (`AddWordsView`: single form, batch paste via
  `PastedWordsParser`, or **AI** generation via KaiAI); swipe to delete.
- **Stats** — Swift Charts dashboard (`StatsAggregator` pure): counts, 7-day bars, accuracy.
- **Settings** — new-words-per-session, pronunciation accent/auto-play, and AI provider +
  API key (`AIConfigStore`, key stored in the Keychain).

Next: share extension + OCR intake, more quiz types, the daily story, and iCloud sync.
