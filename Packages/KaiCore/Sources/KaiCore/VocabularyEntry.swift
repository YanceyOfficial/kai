import Foundation
import SwiftData

/// 一个词条(单词或短语)及其 AI 生成内容与 FSRS 调度状态。
/// CloudKit 兼容:所有持久属性有默认值或可选;去重在仓储层做,不用 .unique。
@Model
public final class VocabularyEntry {
    /// 稳定主键。
    public var id: UUID = UUID()
    /// 原文(保留大小写用于展示)。
    public var lemma: String = ""
    /// 归一化小写键,供去重查询(避免在 #Predicate 里做大小写转换)。
    public var lemmaKey: String = ""

    /// kind/language/source 以 raw 持久化,保证谓词查询稳定。
    public var kindRaw: String = EntryKind.word.rawValue
    public var languageRaw: String = LanguageDomain.english.rawValue
    public var sourceRaw: String = EntrySource.manual.rawValue

    public var phonetic: String = ""
    public var syllables: [String] = []
    public var explanation: String = ""
    public var partsOfSpeech: [String] = []
    public var examples: [Example] = []
    public var story: String?
    public var mnemonic: String?
    public var etymology: String?
    public var synonyms: [String] = []
    public var confusables: [String] = []
    public var tags: [String] = []
    public var isMarked: Bool = false
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    /// Embedded FSRS scheduling state. Mutate only via reschedule(_:) so the queryable dueAt mirror stays in sync.
    public private(set) var scheduling: SchedulingState = SchedulingState.new()

    /// Top-level mirror of scheduling.due, kept in sync by reschedule(_:). SwiftData #Predicate cannot filter on a sub-field of the embedded Codable scheduling struct, so due-date queries use this field instead.
    public private(set) var dueAt: Date = Date()

    /// Updates the scheduling state and keeps the dueAt mirror consistent. This is the only supported way to change scheduling.
    public func reschedule(_ state: SchedulingState) {
        scheduling = state
        dueAt = state.due
    }

    // MARK: 强类型访问器

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
        partsOfSpeech: [String] = [],
        examples: [Example] = [],
        story: String? = nil,
        mnemonic: String? = nil,
        etymology: String? = nil,
        synonyms: [String] = [],
        confusables: [String] = [],
        tags: [String] = [],
        source: EntrySource = .manual,
        isMarked: Bool = false,
        now: Date = .now
    ) {
        self.id = UUID()
        self.lemma = lemma
        self.lemmaKey = lemma.lowercased()
        self.kindRaw = kind.rawValue
        self.languageRaw = language.rawValue
        self.sourceRaw = source.rawValue
        self.phonetic = phonetic
        self.syllables = syllables
        self.explanation = explanation
        self.partsOfSpeech = partsOfSpeech
        self.examples = examples
        self.story = story
        self.mnemonic = mnemonic
        self.etymology = etymology
        self.synonyms = synonyms
        self.confusables = confusables
        self.tags = tags
        self.isMarked = isMarked
        self.createdAt = now
        self.updatedAt = now
        self.scheduling = SchedulingState.new(now: now)
        self.dueAt = self.scheduling.due
    }
}
