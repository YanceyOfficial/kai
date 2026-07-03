import Foundation
import SwiftData

/// Repository protocol for vocabulary entries. Consumers depend on the protocol, not the concrete type, for substitutability and testing.
public protocol VocabularyRepositoryProtocol {
    @discardableResult
    func insertIfAbsent(_ entry: VocabularyEntry) throws -> Bool
    func entry(lemma: String, language: LanguageDomain) throws -> VocabularyEntry?
    func entries(for language: LanguageDomain) throws -> [VocabularyEntry]
    func delete(_ entry: VocabularyEntry) throws
    func logReview(_ log: ReviewLog) throws
    func dueEntries(for language: LanguageDomain, asOf now: Date) throws -> [VocabularyEntry]
    func reviewLogs(entryID: UUID) throws -> [ReviewLog]
    func allReviewLogs() throws -> [ReviewLog]
}

/// SwiftData-backed vocabulary repository implementation.
public final class VocabularyRepository: VocabularyRepositoryProtocol {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Inserts an entry if no entry with the same lemma (case-insensitive) exists in the same language, returning true; otherwise returns false.
    @discardableResult
    public func insertIfAbsent(_ entry: VocabularyEntry) throws -> Bool {
        if try self.entry(lemma: entry.lemma, language: entry.language) != nil {
            return false
        }
        context.insert(entry)
        try context.save()
        return true
    }

    /// Fetches an entry by normalized lemma and language, returning nil if not found.
    public func entry(lemma: String, language: LanguageDomain) throws -> VocabularyEntry? {
        let key = lemma.lowercased()
        let lang = language.rawValue
        var descriptor = FetchDescriptor<VocabularyEntry>(
            predicate: #Predicate { $0.lemmaKey == key && $0.languageRaw == lang }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Fetches all entries for the specified language, sorted by createdAt in ascending order.
    public func entries(for language: LanguageDomain) throws -> [VocabularyEntry] {
        let lang = language.rawValue
        let descriptor = FetchDescriptor<VocabularyEntry>(
            predicate: #Predicate { $0.languageRaw == lang },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    public func delete(_ entry: VocabularyEntry) throws {
        context.delete(entry)
        try context.save()
    }

    /// Writes a single review log entry.
    public func logReview(_ log: ReviewLog) throws {
        context.insert(log)
        try context.save()
    }

    /// Fetches entries for the given language whose due date is not later than `now`, sorted by due date ascending.
    /// Filters on the top-level `dueAt` mirror (kept in sync with `scheduling.due`), since SwiftData
    /// `#Predicate` cannot filter on a sub-field of an embedded Codable struct.
    public func dueEntries(for language: LanguageDomain, asOf now: Date) throws -> [VocabularyEntry] {
        let lang = language.rawValue
        let descriptor = FetchDescriptor<VocabularyEntry>(
            predicate: #Predicate { $0.languageRaw == lang && $0.dueAt <= now },
            sortBy: [SortDescriptor(\.dueAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    /// Fetches all review logs for a given entry, sorted by timestamp ascending.
    public func reviewLogs(entryID: UUID) throws -> [ReviewLog] {
        let descriptor = FetchDescriptor<ReviewLog>(
            predicate: #Predicate { $0.entryID == entryID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    /// Fetches every review log across all entries, sorted by timestamp ascending.
    /// Used by the statistics dashboard.
    public func allReviewLogs() throws -> [ReviewLog] {
        let descriptor = FetchDescriptor<ReviewLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
}
