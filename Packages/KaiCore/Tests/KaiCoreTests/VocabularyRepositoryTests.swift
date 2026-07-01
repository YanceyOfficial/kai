import Foundation
import SwiftData
import Testing
@testable import KaiCore

@MainActor
private func makeRepo() throws -> (VocabularyRepository, ModelContext) {
    let container = try KaiModelContainer.inMemory()
    let ctx = container.mainContext
    return (VocabularyRepository(context: ctx), ctx)
}

@MainActor
@Test("同语言同 lemma 去重(大小写不敏感)")
func dedupeSameLanguageCaseInsensitive() throws {
    let (repo, _) = try makeRepo()
    let first = try repo.insertIfAbsent(VocabularyEntry(lemma: "Eccentric", kind: .word, language: .english))
    let second = try repo.insertIfAbsent(VocabularyEntry(lemma: "eccentric", kind: .word, language: .english))
    #expect(first == true)
    #expect(second == false)
    #expect(try repo.entries(for: .english).count == 1)
}

@MainActor
@Test("不同语言相同 lemma 允许共存")
func sameLemmaDifferentLanguageAllowed() throws {
    let (repo, _) = try makeRepo()
    _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "kanji", kind: .word, language: .english))
    let jp = try repo.insertIfAbsent(VocabularyEntry(lemma: "kanji", kind: .word, language: .japanese))
    #expect(jp == true)
    #expect(try repo.entries(for: .english).count == 1)
    #expect(try repo.entries(for: .japanese).count == 1)
}

@MainActor
@Test("按语言隔离查询")
func entriesFilteredByLanguage() throws {
    let (repo, _) = try makeRepo()
    _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "apple", kind: .word, language: .english))
    _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "banana", kind: .word, language: .english))
    #expect(try repo.entries(for: .japanese).isEmpty)
    #expect(try repo.entries(for: .english).count == 2)
    #expect(try repo.entry(lemma: "APPLE", language: .english)?.lemma == "apple")
}
