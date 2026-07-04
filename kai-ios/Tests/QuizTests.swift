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

private func word(_ lemma: String, _ meaning: String, quizzes: [Quiz] = []) -> VocabularyEntry {
    VocabularyEntry(lemma: lemma, kind: .word, language: .english, explanation: meaning, quizzes: quizzes)
}

@Suite("QuizGenerator")
struct QuizGeneratorTests {
    private let gen = QuizGenerator()

    @Test("Fallback single-choice: choices include the target's meaning as the answer")
    func fallbackMeaningQuestion() {
        let target = word("eccentric", "古怪的")
        let pool = [target, word("obsession", "痴迷"), word("meticulous", "细致的"), word("brisk", "轻快的")]
        var rng = SeededRNG(seed: 42)
        let question = try! #require(gen.makeQuestion(for: target, pool: pool, using: &rng))
        #expect(question.type == .singleChoice)
        #expect(question.choices.count == 4)
        #expect(question.answers == ["古怪的"])
        #expect(question.word == "eccentric")
        let correct = try! #require(question.choices.firstIndex { question.answers.contains($0) })
        #expect(question.isCorrect(choiceIndex: correct))
    }

    @Test("Option count shrinks when there are few distractors")
    func fewDistractors() {
        let target = word("eccentric", "古怪的")
        let pool = [target, word("obsession", "痴迷")]
        var rng = SeededRNG(seed: 7)
        let question = try! #require(gen.makeQuestion(for: target, pool: pool, using: &rng))
        #expect(question.choices.count == 2)
        #expect(question.choices.contains("古怪的"))
        #expect(question.choices.contains("痴迷"))
    }

    @Test("Returns nil without a meaning or distractors (and no AI quiz)")
    func returnsNil() {
        var rng = SeededRNG(seed: 1)
        #expect(gen.makeQuestion(for: word("blank", ""), pool: [word("x", "y")], using: &rng) == nil)
        let lonely = word("alone", "孤单")
        #expect(gen.makeQuestion(for: lonely, pool: [lonely], using: &rng) == nil)
    }

    @Test("Prefers an AI text-entry quiz when the entry has one")
    func prefersAIQuiz() {
        let e = word("use", "v. 使用", quizzes: [
            Quiz(type: .fillInBlank, question: "Make ____ of it.", choices: [], answers: ["use"]),
        ])
        var rng = SeededRNG(seed: 3)
        let q = try! #require(gen.makeQuestion(for: e, pool: [e], using: &rng))
        #expect(q.type == .fillInBlank)
        #expect(q.isTextEntry)
        #expect(q.hidesWord)
        #expect(q.isCorrect(text: "  USE ") == true)    // case/whitespace-insensitive
        #expect(q.isCorrect(text: "used") == false)
    }

    @Test("Skips unusable AI quizzes and falls back")
    func skipsBadAIQuiz() {
        // A choice quiz whose choices don't contain the answer is unusable → fallback.
        let e = word("eccentric", "古怪的", quizzes: [
            Quiz(type: .meaningMatch, question: "?", choices: ["a", "b"], answers: ["c"]),
        ])
        let pool = [e, word("obsession", "痴迷")]
        var rng = SeededRNG(seed: 5)
        let q = try! #require(gen.makeQuestion(for: e, pool: pool, using: &rng))
        #expect(q.type == .singleChoice)                 // fell back
        #expect(q.answers == ["古怪的"])
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

    @Test("A correct answer is a no-op — the review already graded it")
    func correctAnswerIsNoOp() throws {
        let (store, repo) = try makeSeededStore()
        store.load()
        let question = try #require(store.questions.first)
        let correct = try #require(question.choices.firstIndex { question.answers.contains($0) })

        #expect(store.submit(question, .choice(correct)) == true)
        #expect(try repo.reviewLogs(entryID: question.id).isEmpty)
    }

    @Test("A wrong answer re-grades a graduated word as again (the double-check catch)")
    func wrongAnswerGradesAgain() throws {
        let (store, repo) = try makeSeededStore()
        store.load()
        let question = try #require(store.questions.first)
        let entry = try #require(repo.entries(for: .english).first { $0.id == question.id })
        entry.reschedule(SchedulingState(
            stability: 10, difficulty: 5, due: Date(), lastReview: Date(),
            reps: 3, lapses: 0, state: .review))

        let wrong = try #require(question.choices.firstIndex { !question.answers.contains($0) })
        #expect(store.submit(question, .choice(wrong)) == false)

        #expect(entry.scheduling.lapses == 1)
        #expect(try repo.reviewLogs(entryID: question.id).first?.rating == .again)
    }
}
