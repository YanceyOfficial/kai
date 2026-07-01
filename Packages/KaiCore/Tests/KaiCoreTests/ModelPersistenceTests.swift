import Foundation
import SwiftData
import Testing
@testable import KaiCore

@MainActor
@Test("词条可持久化并读回,枚举访问器一致")
func entryPersistsAndReadsBack() throws {
    let container = try KaiModelContainer.inMemory()
    let ctx = container.mainContext

    let entry = VocabularyEntry(
        lemma: "Eccentric",
        kind: .word,
        language: .english,
        explanation: "adj. 古怪的",
        examples: [Example(sentence: "He is eccentric.", translation: "他很古怪。")]
    )
    ctx.insert(entry)
    try ctx.save()

    let fetched = try ctx.fetch(FetchDescriptor<VocabularyEntry>())
    #expect(fetched.count == 1)
    #expect(fetched.first?.lemma == "Eccentric")
    #expect(fetched.first?.lemmaKey == "eccentric")
    #expect(fetched.first?.kind == .word)
    #expect(fetched.first?.language == .english)
    #expect(fetched.first?.scheduling.state == .new)
    #expect(fetched.first?.examples.count == 1)
}

@MainActor
@Test("复习日志可持久化")
func reviewLogPersists() throws {
    let container = try KaiModelContainer.inMemory()
    let ctx = container.mainContext
    let log = ReviewLog(entryID: UUID(), rating: .good, quizType: .singleChoice, elapsedMs: 1200, isCorrect: true)
    ctx.insert(log)
    try ctx.save()

    let fetched = try ctx.fetch(FetchDescriptor<ReviewLog>())
    #expect(fetched.count == 1)
    #expect(fetched.first?.rating == .good)
    #expect(fetched.first?.quizType == .singleChoice)
    #expect(fetched.first?.isCorrect == true)
}
