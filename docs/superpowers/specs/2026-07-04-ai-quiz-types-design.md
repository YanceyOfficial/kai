# AI Quiz Types

Date: 2026-07-04
Status: Draft (awaiting review)
Feature branch: `feature/native-english-mvp`

## Goal

The model already generates 6 quiz types per card, but they're discarded — the quiz only
ever asks single-choice "pick the meaning." Persist the generated quizzes and render varied
retrieval practice (choice **and** typed answers), which is far stronger for memory.

Scope (confirmed): support **choice-based** (singleChoice, meaningMatch, contextCloze) and
**text-entry** (fillInBlank, listeningSpelling) — 5 types via 2 UIs. `splitCombine` is
stored but not rendered yet.

## Design

### KaiCore

- **`Quiz`** value type (Codable, Hashable, Sendable):
  `{ type: QuizType, question: String, choices: [String], answers: [String], translation: String }`.
- `VocabularyEntry` gains `quizzes: [Quiz] = []` (+ init param).

### KaiAI → mapper

`AICardMapper.entry(from:)` maps `card.quizzes` → `[Quiz]`, resolving `GeneratedQuiz.type`
(String) to `QuizType`; entries whose type is unknown are dropped. All known types are
persisted (including `splitCombine`, for future use).

### App — quiz layer

- **`QuizQuestion`** (generalized):
  `{ id: UUID (= entry id), type, word, phonetic, question, choices, answers, translation }`.
  - `isTextEntry` ⇒ `choices.isEmpty` (fillInBlank, listeningSpelling).
  - `hidesWord` ⇒ `type == .listeningSpelling` (word hidden until answered; audio plays).
  - Pure grading: `isCorrect(choiceIndex:)` (option ∈ answers) and `isCorrect(text:)`
    (normalized input ∈ normalized answers, i.e. lowercased + trimmed).
- **`QuizGenerator.makeQuestion(for:pool:using:)`** (blend):
  1. From the entry's `quizzes`, take supported types (not `splitCombine`); for choice types
     require non-empty `choices` containing at least one answer; for text types force
     `choices = []`. Pick one at random.
  2. If none, fall back to the existing single-choice-from-meanings generator.
- **`QuizStore`**: `submit(_ question, _ response)` where `QuizResponse = .choice(Int) | .text(String)`
  returns correctness. Double-check semantics unchanged: a **wrong** answer reschedules the
  word as `again` + logs; a **correct** answer is a no-op.
- **`QuizSessionView`** renders by mode:
  - **Choice**: word + question sentence + tappable options (current styling).
  - **Text**: word (or hidden, for listening) + question + a `TextField` and Submit; on
    submit, show correct/incorrect feedback (reveal the answer) then advance.
  - **Listening**: word hidden, a speaker button auto-plays the pronunciation; answer is the
    word.

## Testing

- **App suite:**
  - `AICardMapper` maps generated quizzes onto the entry (type resolved, unknown dropped).
  - `QuizGenerator` prefers an AI quiz when present (correct type/answers) and falls back to
    single-choice otherwise.
  - Grading: `isCorrect(choiceIndex:)` and `isCorrect(text:)` incl. case/whitespace
    insensitivity.
- Existing quiz tests updated to the new `QuizQuestion` shape / `submit` API.
- `QuizSessionView` text/audio UI is compiled, exercised manually.

## Non-goals

- `splitCombine` rendering (stored only; a syllable-ordering UI comes later).
- Multiple questions per word in one session (one picked question per reviewed word).
- Regenerating quizzes for existing words that predate this change (they use the fallback).

## Open questions

None outstanding.
