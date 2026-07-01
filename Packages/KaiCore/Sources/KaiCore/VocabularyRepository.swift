import Foundation
import SwiftData

/// 词条仓储协议。UI/服务层依赖协议而非具体实现,便于替换与测试。
public protocol VocabularyRepositoryProtocol {
    @discardableResult
    func insertIfAbsent(_ entry: VocabularyEntry) throws -> Bool
    func entry(lemma: String, language: LanguageDomain) throws -> VocabularyEntry?
    func entries(for language: LanguageDomain) throws -> [VocabularyEntry]
    func delete(_ entry: VocabularyEntry) throws
}

/// 基于 SwiftData 的词条仓储实现。
public final class VocabularyRepository: VocabularyRepositoryProtocol {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// 若同语言下不存在相同 lemma(大小写不敏感)则插入并返回 true,否则返回 false。
    @discardableResult
    public func insertIfAbsent(_ entry: VocabularyEntry) throws -> Bool {
        if try self.entry(lemma: entry.lemma, language: entry.language) != nil {
            return false
        }
        context.insert(entry)
        try context.save()
        return true
    }

    /// 按归一化 lemma + 语言精确查一条。
    public func entry(lemma: String, language: LanguageDomain) throws -> VocabularyEntry? {
        let key = lemma.lowercased()
        let lang = language.rawValue
        var descriptor = FetchDescriptor<VocabularyEntry>(
            predicate: #Predicate { $0.lemmaKey == key && $0.languageRaw == lang }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// 按语言隔离取全部词条,按创建时间升序。
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
