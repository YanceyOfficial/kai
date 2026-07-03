# AI Card Enrichment v2 — Bilingual, Annotations, Collocations

Date: 2026-07-03
Status: Draft (awaiting review)
Feature branch: `feature/native-english-mvp`

## Goal

Extend the AI-generated word card with three user-requested enrichments:

1. **Bilingual content** — English *and* Chinese for Meaning, Similar-words sense, and
   Notes, so the learner gets both the English definition (English-English study) and a
   quick Chinese gloss.
2. **Annotations** — a user-authored, comment-like module for modern/contextual senses
   the AI (which produces standard, textbook content) would not include.
3. **Collocations** — the AI also produces fixed collocations / phrases for a word
   (e.g. `use` → `used to`, `make use of`), each with a bilingual meaning and example.

Native language is **fixed to Chinese** for this MVP (target language = English), matching
the existing example-sentence translation pattern (`Example { sentence; translation }`).

## Non-goals

- Making the native language configurable (deferred).
- Changing the Words list row or the quiz meaning source — both keep using `explanation`
  (English) as the primary meaning. No search/quiz changes.
- Bilingual treatment of `confusables` (a bare word list; no gloss needed).

## Design

### 1. Bilingual content — parallel EN + ZH fields

Chosen over a shared `Bilingual { en; zh }` value type: parallel optional fields match the
existing `Example` idiom, avoid migrating the core `explanation` string (which list/search
depend on) into a struct, and let the UI hide the ZH line when absent.

**`KaiCore.VocabularyEntry`** — add:

| Field | Type | Notes |
|-------|------|-------|
| `explanationZh` | `String?` | Chinese meaning; `explanation` stays the English definition. |
| `mnemonicZh` | `String?` | Chinese version of the mnemonic. |
| `etymologyZh` | `String?` | Chinese version of the etymology. |
| `rootsZh` | `String?` | Chinese version of the morpheme breakdown. |

**`KaiCore.SynonymGroup`** — add `senseZh: String?` (Chinese gloss of the shared sense).

**Display (`WordDetailView`):** Meaning, Similar words, and Notes each render the English
text, then the Chinese text below in `KaiColor.inkSecondary` — the same two-line pattern
already used for example sentences. ZH lines are omitted when nil/empty.

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
    public var phrase: String
    public var meaning: String            // English gloss
    public var meaningZh: String          // Chinese gloss ("" when N/A)
    public var example: String            // example sentence ("" when N/A)
    public var exampleTranslation: String // Chinese translation ("" when N/A)
}
```

Stored on `VocabularyEntry` as `collocations: [Collocation] = []`.

**Display (`WordDetailView`):** a new **Collocations** section — each row shows the phrase
(emphasis), the bilingual meaning, and the example sentence with its translation below.

### AI layer (KaiAI)

**`GeneratedCard`** — add:
- `explanationZh: String`, `mnemonicZh: String`, `etymologyZh: String`, `rootsZh: String`
  (all non-optional, `""` when N/A — consistent with the existing `mnemonic`/`etymology`
  string fields; the mapper converts `""` → `nil`).
- `GeneratedSynonymGroup` gains `senseZh: String`.
- `collocations: [GeneratedCollocation]` where
  `GeneratedCollocation { phrase, meaning, meaningZh, example, exampleTranslation }`.

**`CardSchema`** — add the matching JSON-Schema properties; all required (OpenAI strict
mode). The model returns an empty string for any bilingual/collocation field that does not
apply.

**`PromptBuilder`** — extend the system prompt to:
- Provide a Chinese translation alongside each of: explanation, synonym `sense`, roots,
  mnemonic, etymology.
- Produce `collocations`: fixed collocations / phrases the word commonly forms, each with
  `phrase`, a bilingual `meaning`, and one `example` + `exampleTranslation`. Empty array
  when the word forms no notable collocations.

**`AICardMapper`** — map the new fields into `VocabularyEntry`, converting empty strings to
`nil` for the optional `*Zh` fields.

### Migration & seed

- SwiftData migration is lightweight: all new columns are optional or defaulted arrays
  (CloudKit-compatible modeling — no `@Attribute(.unique)`).
- `StarterSeed`: set English `explanation` + Chinese `explanationZh`, add `senseZh` to the
  synonym groups, and add one sample `Collocation` to at least one entry.

## Testing

- **KaiAI** (`GeneratedCardTests`): extend the decode fixture with the new bilingual fields
  and a `collocations` entry; assert they decode. Keep the existing "roots optional" test.
- **App** (`AICardMapperTests`): assert the new fields map onto `VocabularyEntry`
  (bilingual glosses, collocations).
- **KaiCore** (simulator suite): a small test that appending and removing an `Annotation`
  on a persisted `VocabularyEntry` round-trips.
- Full app suite + KaiCore (simulator) + KaiAI/KaiFSRS/KaiServices (`swift test`) stay green.

## Open questions

None outstanding. (The bilingual-modeling approach was chosen as parallel EN+ZH fields.)
