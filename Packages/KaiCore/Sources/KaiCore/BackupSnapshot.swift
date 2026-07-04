import Foundation
import SwiftData

/// How an imported backup reconciles with words already in the deck.
public enum BackupImportStrategy: Sendable {
    /// Overwrite existing words (same lemma) with the backup's version + progress; add the rest.
    case mergeBackupWins
    /// Keep existing words untouched; only add words not already present.
    case mergeKeepExisting
    /// Wipe the deck, then import the backup exactly.
    case replaceAll
}

/// A full, portable, `Codable` snapshot of the local database — every word (with its FSRS
/// scheduling state, so progress is preserved), review logs, and daily stories. Exported to
/// / imported from a JSON file via the Files app; the app stays fully on-device.
public struct BackupSnapshot: Codable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var exportedAt: Date
    public var entries: [Entry]
    public var logs: [Log]
    public var stories: [Story]

    public struct Entry: Codable, Sendable {
        public var id: UUID
        public var lemma: String
        public var kindRaw: String
        public var languageRaw: String
        public var sourceRaw: String
        public var phonetic: String
        public var syllables: [String]
        public var explanation: String
        public var explanationEn: String?
        public var partsOfSpeech: [String]
        public var examples: [Example]
        public var story: String?
        public var mnemonic: String?
        public var etymology: String?
        public var roots: String?
        public var synonymGroups: [SynonymGroup]
        public var collocations: [Collocation]
        public var annotations: [Annotation]
        public var confusables: [String]
        public var tags: [String]
        public var isMarked: Bool
        public var createdAt: Date
        public var updatedAt: Date
        public var scheduling: SchedulingState
    }

    public struct Log: Codable, Sendable {
        public var id: UUID
        public var entryID: UUID
        public var timestamp: Date
        public var ratingRaw: Int
        public var quizTypeRaw: String
        public var elapsedMs: Int
        public var isCorrect: Bool
    }

    public struct Story: Codable, Sendable {
        public var id: UUID
        public var day: Date
        public var languageRaw: String
        public var text: String
        public var translation: String
        public var wordLemmas: [String]
        public var createdAt: Date
    }
}

public extension VocabularyRepository {
    /// Builds a complete snapshot of the store for export.
    func exportSnapshot(now: Date = .now) throws -> BackupSnapshot {
        let entries = try context.fetch(FetchDescriptor<VocabularyEntry>())
        let logs = try context.fetch(FetchDescriptor<ReviewLog>())
        let stories = try context.fetch(FetchDescriptor<DailyStory>())
        return BackupSnapshot(
            schemaVersion: BackupSnapshot.currentSchemaVersion,
            exportedAt: now,
            entries: entries.map(Self.dto(from:)),
            logs: logs.map(Self.dto(from:)),
            stories: stories.map(Self.dto(from:))
        )
    }

    private static func dto(from e: VocabularyEntry) -> BackupSnapshot.Entry {
        BackupSnapshot.Entry(
            id: e.id, lemma: e.lemma, kindRaw: e.kindRaw, languageRaw: e.languageRaw,
            sourceRaw: e.sourceRaw, phonetic: e.phonetic, syllables: e.syllables,
            explanation: e.explanation, explanationEn: e.explanationEn,
            partsOfSpeech: e.partsOfSpeech, examples: e.examples, story: e.story,
            mnemonic: e.mnemonic, etymology: e.etymology, roots: e.roots,
            synonymGroups: e.synonymGroups, collocations: e.collocations,
            annotations: e.annotations, confusables: e.confusables, tags: e.tags,
            isMarked: e.isMarked, createdAt: e.createdAt, updatedAt: e.updatedAt,
            scheduling: e.scheduling)
    }

    private static func dto(from l: ReviewLog) -> BackupSnapshot.Log {
        BackupSnapshot.Log(id: l.id, entryID: l.entryID, timestamp: l.timestamp,
                           ratingRaw: l.ratingRaw, quizTypeRaw: l.quizTypeRaw,
                           elapsedMs: l.elapsedMs, isCorrect: l.isCorrect)
    }

    private static func dto(from s: DailyStory) -> BackupSnapshot.Story {
        BackupSnapshot.Story(id: s.id, day: s.day, languageRaw: s.languageRaw,
                             text: s.text, translation: s.translation,
                             wordLemmas: s.wordLemmas, createdAt: s.createdAt)
    }

    /// Imports a snapshot with the given reconciliation strategy. Returns the number of
    /// words written. Preserves ids so review logs stay linked to their words.
    @discardableResult
    func importSnapshot(_ snapshot: BackupSnapshot, strategy: BackupImportStrategy) throws -> Int {
        if strategy == .replaceAll {
            for e in try context.fetch(FetchDescriptor<VocabularyEntry>()) { context.delete(e) }
            for l in try context.fetch(FetchDescriptor<ReviewLog>()) { context.delete(l) }
            for s in try context.fetch(FetchDescriptor<DailyStory>()) { context.delete(s) }
        }

        var imported = 0
        for dto in snapshot.entries {
            let key = dto.lemma.lowercased()
            let lang = dto.languageRaw
            let existing = try context.fetch(FetchDescriptor<VocabularyEntry>(
                predicate: #Predicate { $0.lemmaKey == key && $0.languageRaw == lang }))
            if !existing.isEmpty {
                if strategy == .mergeKeepExisting { continue }
                for e in existing { context.delete(e) }   // backup wins
            }
            context.insert(makeEntry(dto))
            imported += 1
        }

        // Logs: add any whose id isn't already present (dedupe).
        let existingLogIDs = Set(try context.fetch(FetchDescriptor<ReviewLog>()).map(\.id))
        for dto in snapshot.logs where !existingLogIDs.contains(dto.id) {
            context.insert(makeLog(dto))
        }

        // Stories: one per day+language.
        for dto in snapshot.stories {
            let day = dto.day, lang = dto.languageRaw
            let existing = try context.fetch(FetchDescriptor<DailyStory>(
                predicate: #Predicate { $0.day == day && $0.languageRaw == lang }))
            for s in existing { context.delete(s) }
            context.insert(makeStory(dto))
        }

        try context.save()
        return imported
    }

    private func makeEntry(_ dto: BackupSnapshot.Entry) -> VocabularyEntry {
        let entry = VocabularyEntry(
            lemma: dto.lemma, kind: EntryKind(rawValue: dto.kindRaw) ?? .word,
            language: LanguageDomain(rawValue: dto.languageRaw) ?? .english,
            phonetic: dto.phonetic, syllables: dto.syllables, explanation: dto.explanation,
            explanationEn: dto.explanationEn, partsOfSpeech: dto.partsOfSpeech,
            examples: dto.examples, story: dto.story, mnemonic: dto.mnemonic,
            etymology: dto.etymology, roots: dto.roots, synonymGroups: dto.synonymGroups,
            collocations: dto.collocations, annotations: dto.annotations,
            confusables: dto.confusables, tags: dto.tags,
            source: EntrySource(rawValue: dto.sourceRaw) ?? .manual, isMarked: dto.isMarked,
            now: dto.createdAt)
        entry.id = dto.id
        entry.createdAt = dto.createdAt
        entry.updatedAt = dto.updatedAt
        entry.reschedule(dto.scheduling)   // restores stability/difficulty/due/reps/lapses
        return entry
    }

    private func makeLog(_ dto: BackupSnapshot.Log) -> ReviewLog {
        let log = ReviewLog(
            entryID: dto.entryID, rating: ReviewRating(rawValue: dto.ratingRaw) ?? .good,
            quizType: QuizType(rawValue: dto.quizTypeRaw) ?? .singleChoice,
            elapsedMs: dto.elapsedMs, isCorrect: dto.isCorrect, timestamp: dto.timestamp)
        log.id = dto.id
        return log
    }

    private func makeStory(_ dto: BackupSnapshot.Story) -> DailyStory {
        let story = DailyStory(
            day: dto.day, language: LanguageDomain(rawValue: dto.languageRaw) ?? .english,
            text: dto.text, translation: dto.translation, wordLemmas: dto.wordLemmas,
            now: dto.createdAt)
        story.id = dto.id
        story.createdAt = dto.createdAt
        return story
    }
}
