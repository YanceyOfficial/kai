import Testing
import Foundation
import SwiftData
@testable import kai_ios
import KaiCore

/// A small deterministic RNG so shuffles are reproducible in tests.
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private func word(_ lemma: String, _ meaning: String) -> VocabularyEntry {
    VocabularyEntry(lemma: lemma, kind: .word, language: .english, explanation: meaning)
}

@Suite("QuizGenerator")
struct QuizGeneratorTests {
    private let gen = QuizGenerator()

    @Test("The correct index points at the target's meaning")
    func correctIndexIsRight() {
        let target = word("eccentric", "古怪的")
        let pool = [target, word("obsession", "痴迷"), word("meticulous", "细致的"), word("brisk", "轻快的")]
        var rng = SeededRNG(seed: 42)
        let q = gen.makeQuestion(for: target, pool: pool, using: &rng)
        let question = try! #require(q)
        #expect(question.options.count == 4)
        #expect(question.options[question.correctIndex] == "古怪的")
        #expect(question.prompt == "eccentric")
    }

    @Test("Option count shrinks when there are few distractors")
    func fewDistractors() {
        let target = word("eccentric", "古怪的")
        let pool = [target, word("obsession", "痴迷")]
        var rng = SeededRNG(seed: 7)
        let question = try! #require(gen.makeQuestion(for: target, pool: pool, using: &rng))
        #expect(question.options.count == 2)   // 1 correct + 1 distractor
        #expect(question.options.contains("古怪的"))
        #expect(question.options.contains("痴迷"))
    }

    @Test("Returns nil without a meaning or without distractors")
    func returnsNil() {
        var rng = SeededRNG(seed: 1)
        // No meaning on the target.
        #expect(gen.makeQuestion(for: word("blank", ""), pool: [word("x", "y")], using: &rng) == nil)
        // No other entries to draw distractors from.
        let lonely = word("alone", "孤单")
        #expect(gen.makeQuestion(for: lonely, pool: [lonely], using: &rng) == nil)
    }

    @Test("Duplicate meanings are not repeated as options")
    func dedupesDistractors() {
        let target = word("eccentric", "古怪的")
        let pool = [target, word("a", "same"), word("b", "same"), word("c", "different")]
        var rng = SeededRNG(seed: 99)
        let question = try! #require(gen.makeQuestion(for: target, pool: pool, using: &rng))
        #expect(Set(question.options).count == question.options.count)
    }
}

@MainActor
@Suite(.serialized)
struct QuizStoreTests {
    private func makeSeededStore() throws -> (QuizStore, VocabularyRepository) {
        let context = ModelContext(try KaiModelContainer.inMemory())
        let repository = VocabularyRepository(context: context)
        try StarterSeed.seedIfEmpty(repository)
        return (QuizStore(context: context), repository)
    }

    @Test("Builds a question per seeded word")
    func loadsQuestions() throws {
        let (store, _) = try makeSeededStore()
        store.load()
        #expect(store.questions.count == 3)
    }

    @Test("load(entryIDs:) builds questions only for the given words")
    func loadForSpecificIDs() throws {
        let (store, repo) = try makeSeededStore()
        let target = try #require(repo.entries(for: .english).first)
        store.load(entryIDs: [target.id])
        #expect(store.questions.count == 1)
        #expect(store.questions.first?.id == target.id)
    }

    @Test("A correct answer grades good and logs it")
    func correctAnswerGradesGood() throws {
        let (store, repo) = try makeSeededStore()
        store.load()
        let question = try #require(store.questions.first)

        #expect(store.answer(question, selectedIndex: question.correctIndex) == true)

        let logs = try repo.reviewLogs(entryID: question.id)
        #expect(logs.count == 1)
        #expect(logs.first?.rating == .good)
        #expect(logs.first?.isCorrect == true)
    }

    @Test("A wrong answer grades again and records a lapse")
    func wrongAnswerGradesAgain() throws {
        let (store, repo) = try makeSeededStore()
        store.load()
        let question = try #require(store.questions.first)
        let wrongIndex = (question.correctIndex + 1) % question.options.count

        #expect(store.answer(question, selectedIndex: wrongIndex) == false)

        let entry = try #require(repo.entries(for: .english).first { $0.id == question.id })
        #expect(entry.scheduling.lapses == 1)
        #expect(try repo.reviewLogs(entryID: question.id).first?.rating == .again)
    }
}
