import Foundation
import SwiftData

/// Repository protocol for vocabulary entries. Consumers depend on the protocol, not the concrete type, for substitutability and testing.
public protocol VocabularyRepositoryProtocol {
    @discardableResult
    func insertIfAbsent(_ entry: VocabularyEntry) throws -> Bool
    func entry(lemma: String, language: LanguageDomain) throws -> VocabularyEntry?
    func entries(for language: LanguageDomain) throws -> [VocabularyEntry]
    func delete(_ entry: VocabularyEntry) throws
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
        var descriptor = FetchDescriptor<VocabularyEntry>(
            predicate: #Predicate { $0.languageRaw == lang }
        )
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .forward)]
        return try context.fetch(descriptor)
    }

    public func delete(_ entry: VocabularyEntry) throws {
        context.delete(entry)
        try context.save()
    }
}
