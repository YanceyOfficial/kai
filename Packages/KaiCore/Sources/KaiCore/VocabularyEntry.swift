import Foundation
import SwiftData

/// A vocabulary entry (word or phrase) with its AI-generated content and FSRS scheduling state.
/// CloudKit compatible: all persistent attributes have default values or are optional; deduplication is done at the repository layer, no use of .unique.
@Model
public final class VocabularyEntry {
    /// Stable primary key.
    public var id: UUID = UUID()
    /// Original text (preserve case for display).
    public var lemma: String = ""
    /// Normalized lowercase key for deduplication queries (avoid case conversion in #Predicate).
    public var lemmaKey: String = ""

    /// kind/language/source persisted as raw values to ensure stable predicate queries.
    public var kindRaw: String = EntryKind.word.rawValue
    public var languageRaw: String = LanguageDomain.english.rawValue
    public var sourceRaw: String = EntrySource.manual.rawValue

    public var phonetic: String = ""
    public var syllables: [String] = []
    /// Concise Chinese gloss (part of speech + short meaning) — the primary meaning shown
    /// in the quiz, list row, and detail page.
    public var explanation: String = ""
    /// Fuller English definition, shown only on the detail page (never in the quiz).
    public var explanationEn: String?
    public var partsOfSpeech: [String] = []
    public var examples: [Example] = []
    public var story: String?
    public var mnemonic: String?
    public var etymology: String?
    /// Morpheme breakdown (prefix/root/suffix with meanings); nil when not applicable.
    public var roots: String?
    /// Similar words grouped by shared sense (see `SynonymGroup`).
    public var synonymGroups: [SynonymGroup] = []
    /// Fixed collocations / phrases the word commonly forms (see `Collocation`).
    public var collocations: [Collocation] = []
    /// User-authored notes (see `Annotation`); never AI-generated.
    public var annotations: [Annotation] = []
    public var confusables: [String] = []
    public var tags: [String] = []
    public var isMarked: Bool = false
    public var createdAt: Date = Date()
    /// Timestamp of the last content edit (lemma, explanation, examples, etc.). Scheduling changes do NOT bump this — review recency lives in scheduling.lastReview and ReviewLog.
    public var updatedAt: Date = Date()

    /// Embedded FSRS scheduling state. Mutate only via reschedule(_:) so the queryable dueAt mirror stays in sync.
    public private(set) var scheduling: SchedulingState = SchedulingState.new()

    /// Top-level mirror of scheduling.due, kept in sync by reschedule(_:). SwiftData #Predicate cannot filter on a sub-field of the embedded Codable scheduling struct, so due-date queries use this field instead.
    public private(set) var dueAt: Date = Date()

    /// Updates the scheduling state and keeps the dueAt mirror consistent. This is the only supported way to change scheduling. Intentionally does not touch updatedAt (that tracks content edits only).
    public func reschedule(_ state: SchedulingState) {
        scheduling = state
        dueAt = state.due
    }

    // MARK: Strongly Typed Accessors

    public var kind: EntryKind {
        get { EntryKind(rawValue: kindRaw) ?? .word }
        set { kindRaw = newValue.rawValue }
    }
    public var language: LanguageDomain {
        get { LanguageDomain(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }
    public var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    public init(
        lemma: String,
        kind: EntryKind,
        language: LanguageDomain,
        phonetic: String = "",
        syllables: [String] = [],
        explanation: String = "",
        explanationEn: String? = nil,
        partsOfSpeech: [String] = [],
        examples: [Example] = [],
        story: String? = nil,
        mnemonic: String? = nil,
        etymology: String? = nil,
        roots: String? = nil,
        synonymGroups: [SynonymGroup] = [],
        collocations: [Collocation] = [],
        annotations: [Annotation] = [],
        confusables: [String] = [],
        tags: [String] = [],
        source: EntrySource = .manual,
        isMarked: Bool = false,
        now: Date = .now
    ) {
        self.lemma = lemma
        self.lemmaKey = lemma.lowercased()
        self.kindRaw = kind.rawValue
        self.languageRaw = language.rawValue
        self.sourceRaw = source.rawValue
        self.phonetic = phonetic
        self.syllables = syllables
        self.explanation = explanation
        self.explanationEn = explanationEn
        self.partsOfSpeech = partsOfSpeech
        self.examples = examples
        self.story = story
        self.mnemonic = mnemonic
        self.etymology = etymology
        self.roots = roots
        self.synonymGroups = synonymGroups
        self.collocations = collocations
        self.annotations = annotations
        self.confusables = confusables
        self.tags = tags
        self.isMarked = isMarked
        self.createdAt = now
        self.updatedAt = now
        self.scheduling = SchedulingState.new(now: now)
        self.dueAt = self.scheduling.due
    }
}
