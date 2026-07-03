# AI Card Enrichment v2 — Bilingual, Annotations, Collocations

Date: 2026-07-03
Status: Draft (awaiting review)
Feature branch: `feature/native-english-mvp`

## Goal

Extend the AI-generated word card with three user-requested enrichments:

1. **Chinese-primary meaning** — `explanation` becomes a concise Chinese gloss (like a
   dictionary headword: `vt. 保证；使确信`). This is what the quiz and list row show, so
   single-choice options are short and uniform. The full English definition is kept as a
   secondary line on the word **detail page only** — preserving the English-English study
   value without polluting the quiz.
2. **Annotations** — a user-authored, comment-like module for modern/contextual senses
   the AI (which produces standard, textbook content) would not include.
3. **Collocations** — the AI also produces fixed collocations / phrases for a word
   (e.g. `use` → `used to`, `make use of`), each with a Chinese meaning and example.

Guiding principle: **the English word and its English content** (synonyms, collocation
phrases, example sentences) stay English; **all explanatory glosses** (meaning, sense,
collocation meaning, example translations) are **Chinese** — the learner's native language.
Native language is fixed to Chinese for this MVP.

### Motivation (from testing)

Quiz single-choice options are drawn from other words' `explanation`. When some words had
Chinese explanations (seed) and others English (AI-generated), the option list mixed short
Chinese with long English sentences — unreadable. Standardizing `explanation` to concise
Chinese fixes this.

## Non-goals

- Making the native language configurable (deferred).
- Bilingual treatment of `confusables` (a bare word list; no gloss needed).
- Feeding collocations into the quiz (deferred).

## Design

### 1. Chinese-primary meaning (+ English on detail)

Only **Meaning** is truly bilingual; every other field is already English-content with a
Chinese gloss, so no parallel `*Zh` fields are needed.

**`KaiCore.VocabularyEntry`** — the only change here:

| Field | Type | Notes |
|-------|------|-------|
| `explanation` | `String` (existing) | Now the **concise Chinese** gloss (POS + short meaning). Used by quiz, list row, and detail. |
| `explanationEn` | `String?` (new) | The full **English** definition; shown only on the detail Meaning section, never in the quiz. |

**`KaiCore.SynonymGroup`** — no change: `sense` is the **Chinese** label; `words` are the
English synonyms. (The seed already uses Chinese senses, e.g. `古怪的`.)

**Notes (`roots` / `mnemonic` / `etymology`)** — no new fields; these are generated in
**Chinese**. `roots` keeps the English morpheme forms inline with Chinese meanings
(e.g. `ec-（出）+ centr（中心）+ -ic → 偏离中心`).

**Display (`WordDetailView`):** the Meaning section renders the Chinese `explanation`, then
`explanationEn` below in `KaiColor.inkSecondary` (same two-line pattern as example
sentences); the English line is omitted when nil/empty. Similar words and Notes render their
(Chinese) text directly.

### 2. Annotations — user-authored, never AI

**New value type `KaiCore.Annotation`** (Codable, Hashable, Sendable):

```swift
public struct Annotation: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var text: String
    public var createdAt: Date
}
```

Stored on `VocabularyEntry` as `annotations: [Annotation] = []` (Codable array, same
persistence approach as `synonymGroups`). Not part of the AI schema.

**Display + editing (`WordDetailView`):** a new **Annotations** section:
- Lists annotations newest-first: `createdAt` (abbreviated date) + `text`.
- "Add note" button → a small sheet with a multiline `TextField`; on save, append
  `Annotation(id:.init(), text:, createdAt:.now)` and save the `modelContext`.
- Swipe-to-delete removes an annotation and saves.

This makes `WordDetailView` mutate the entry, so it gains `@Environment(\.modelContext)`.
`entry` is a `@Model` reference type, so mutating `entry.annotations` + `context.save()`
persists.

### 3. Collocations — AI-generated

**New value type `KaiCore.Collocation`** (Codable, Hashable, Sendable):

```swift
public struct Collocation: Codable, Hashable, Sendable {
    public var phrase: String             // the collocation, e.g. "make use of"
    public var meaning: String            // Chinese gloss
    public var example: String            // English example sentence ("" when N/A)
    public var exampleTranslation: String // Chinese translation of the example ("" when N/A)
}
```

Stored on `VocabularyEntry` as `collocations: [Collocation] = []`.

**Display (`WordDetailView`):** a new **Collocations** section — each row shows the phrase
(emphasis), the Chinese meaning, and the example sentence with its translation below.

### AI layer (KaiAI)

**`GeneratedCard`** — changes:
- `explanation` is now the **Chinese** gloss; add `explanationEn: String` (English
  definition, `""` when the model has none). Mapper converts `""` → `nil`.
- `mnemonic` / `etymology` / `roots` are generated in **Chinese** (no new fields).
- `GeneratedSynonymGroup.sense` is **Chinese** (no new field).
- `collocations: [GeneratedCollocation]` where
  `GeneratedCollocation { phrase, meaning, example, exampleTranslation }` (meaning +
  exampleTranslation are Chinese).

**`CardSchema`** — add `explanationEn` and the `collocations` array; all properties required
(OpenAI strict mode). The model returns an empty string for any field that does not apply.

**`PromptBuilder`** — update the system prompt so it:
- Writes `explanation` as a **concise Chinese** gloss (part-of-speech + short meaning, like
  a dictionary headword), and `explanationEn` as the fuller English definition.
- Writes synonym `sense`, `mnemonic`, `etymology`, and the meanings inside `roots` in
  **Chinese** (keeping English morpheme forms inline in `roots`).
- Produces `collocations`: fixed collocations / phrases the word commonly forms, each with
  `phrase` (English), a Chinese `meaning`, and one English `example` + Chinese
  `exampleTranslation`. Empty array when the word forms no notable collocations.

**`AICardMapper`** — map `explanationEn` (empty → nil) and `collocations` into
`VocabularyEntry`.

### Migration & seed

- SwiftData migration is lightweight: all new columns are optional or defaulted arrays
  (CloudKit-compatible modeling — no `@Attribute(.unique)`).
- `StarterSeed`: entries already use Chinese `explanation`; add `explanationEn` and one
  sample `Collocation` to at least one entry. Synonym `sense` values are already Chinese.

## Testing

- **KaiAI** (`GeneratedCardTests`): extend the decode fixture with `explanationEn` and a
  `collocations` entry; assert they decode. Keep the existing "roots optional" test.
- **App** (`AICardMapperTests`): assert `explanationEn` and `collocations` map onto
  `VocabularyEntry`.
- **KaiCore** (simulator suite): a small test that appending and removing an `Annotation`
  on a persisted `VocabularyEntry` round-trips.
- Full app suite + KaiCore (simulator) + KaiAI/KaiFSRS/KaiServices (`swift test`) stay green.

## Open questions

None outstanding.
