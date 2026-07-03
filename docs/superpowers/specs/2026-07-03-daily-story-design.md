# Daily Story (每日故事)

Date: 2026-07-03
Status: Draft (awaiting review)
Feature branch: `feature/native-english-mvp`

## Goal

An AI-woven short English passage that uses **today's due review words**, to reinforce
them in context. Target words are highlighted and tappable (→ their detail card), with a
Chinese-translation toggle. Generated once per day and cached.

Decisions (confirmed): words = today's due review session; placement = an entry on the
Review screen; format = English passage + tap-to-card + Chinese toggle.

## Design

### KaiAI — story generation

- **`GeneratedStory`** DTO: `{ story: String, translation: String }` (English passage +
  Chinese translation).
- **`StorySchema`**: JSON-Schema object `{ story, translation }`, both required,
  `additionalProperties: false`.
- **`PromptBuilder`** gains `storySystemPrompt()` + `storyUserPrompt(words:)`: "Write a
  short, natural, coherent English passage (~80–120 words) that uses ALL of these words at
  least once: […]. Keep it memorable and simple. Then give a faithful Chinese translation."
- **`LLMProvider.generateStory(words:language:) async throws -> GeneratedStory`.**
- **Refactor** `ClaudeProvider`/`OpenAIProvider`: extract the shared request → transport →
  envelope → inner-JSON flow into a private helper returning the inner JSON `Data`;
  `generateCards` and `generateStory` both call it with their schema/prompt. The existing
  provider tests guard the refactor.

### KaiCore — caching

- **`DailyStory`** `@Model` (CloudKit-safe: defaults, no `.unique`):
  `{ id: UUID, day: Date (start of day), languageRaw, text, translation, wordLemmas:
  [String], createdAt }`.
- **`VocabularyRepository`**: `dailyStory(for:on:) -> DailyStory?` (code-layer match on
  day+language) and `upsertDailyStory(_:)` (replace any existing entry for that day+language,
  then insert). Regeneration replaces the day's story.

### App

- **`StoryStore`** (`@MainActor @Observable`):
  - `state: idle | loading | ready(Content) | empty | needsKey | failed(String)`.
  - `Content { text, translation, words: [(lemma, entryID)] }` — the word→entry map lets the
    view highlight and link occurrences.
  - `load()`: compute today's due words (reuse `repository.dueEntries` + `SessionComposer`
    with `newWordsPerDay`, like `ReviewStore`); if the set is empty → `empty`; else if a
    cached `DailyStory` exists for today → `ready`; else `idle` (offer to generate).
  - `generate()` / `regenerate()`: require an API key (else `needsKey`); call
    `provider.generateStory`, persist via `upsertDailyStory`, resolve `wordLemmas` → entry
    IDs, set `ready`. Errors → `failed` + `AppLog`/toast.
- **`StoryView`**:
  - Renders `text` as an `AttributedString`: each occurrence of a target word (case-
    insensitive, word-boundary) is styled (vermilion, semibold) and given a
    `kai://word/<lemma>` link. An `openURL` handler resolves the lemma → entry ID and pushes
    `WordDetailView` in a `NavigationStack`.
  - A `文/A` toggle reveals/hides the Chinese `translation`.
  - Regenerate button; loading spinner; `empty` ("No words due today"), `needsKey` ("Add an
    API key in Settings") states.
- **Entry point**: a book-glyph button in the `ReviewSessionView` header that presents
  `StoryView` as a full-screen sheet. (Avoids a 6th tab.)

## Testing

- **KaiAI** (`swift test`): `GeneratedStory` decodes; `PromptBuilder` story prompt names the
  words and asks for a translation; `ClaudeProvider`/`OpenAIProvider` `generateStory` decode
  via a stub transport; existing card tests still pass (guarding the refactor).
- **KaiCore** (simulator): a `DailyStory` upsert replaces the same-day entry and fetch
  returns it.
- **App** (simulator): `StoryStore` — with a stub provider, empty due set → `empty`; missing
  key → `needsKey`; a successful generate → `ready` with the word→entry map populated.
- **Highlighting** (pure): a small helper `StoryHighlighter.attributed(text:words:)` is unit-
  tested for word-boundary, case-insensitive matching and link URLs — kept pure so it's
  testable without a view.

## Non-goals

- Streaming the story as it generates (one-shot is fine).
- Audio narration / read-aloud (future; pronunciation infra exists but out of scope).
- Story history browsing — only today's story is kept per day (older days may be overwritten
  lazily; no archive UI).

## Open questions

None outstanding.
