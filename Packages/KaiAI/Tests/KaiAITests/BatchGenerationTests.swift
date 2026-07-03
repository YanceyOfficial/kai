import Foundation
import Testing
import KaiCore
@testable import KaiAI

/// A mock provider that returns one card per lemma, but throws for any chunk that
/// contains a lemma starting with "!" — lets us assert chunking and partial-failure.
private struct MockProvider: LLMProvider {
    let chunkSizesSeen: Recorder

    final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private(set) var sizes: [Int] = []
        func record(_ n: Int) { lock.lock(); sizes.append(n); lock.unlock() }
    }

    func generateCards(lemmas: [String], language: LanguageDomain, literaryExamples: Bool) async throws -> [GeneratedCard] {
        chunkSizesSeen.record(lemmas.count)
        if lemmas.contains(where: { $0.hasPrefix("!") }) {
            throw AIError.emptyResponse
        }
        return lemmas.map { card(lemma: $0) }
    }

    private func card(lemma: String) -> GeneratedCard {
        let json = """
        {"lemma":"\(lemma)","kind":"word","phonetic":"","syllables":[],"explanation":"",
        "explanationEn":"","partsOfSpeech":[],"examples":[],"mnemonic":"","etymology":"",
        "synonyms":[],"collocations":[],"confusables":[],"quizzes":[]}
        """
        return try! JSONDecoder().decode(GeneratedCard.self, from: Data(json.utf8))
    }
}

@Test("Batch generation splits lemmas into chunks of at most chunkSize")
func batchesIntoChunks() async {
    let recorder = MockProvider.Recorder()
    let provider = MockProvider(chunkSizesSeen: recorder)
    let lemmas = (1...25).map { "w\($0)" }

    let outcome = await provider.generateCards(lemmas: lemmas, language: .english, literaryExamples: false, chunkSize: 10)

    #expect(outcome.cards.count == 25)
    #expect(recorder.sizes == [10, 10, 5])   // 25 split into 10/10/5
    #expect(outcome.failures.isEmpty)
    #expect(outcome.cards.map(\.lemma) == lemmas)   // input order preserved
}

@Test("A failing chunk is recorded but does not abort the rest")
func partialFailureIsBestEffort() async {
    let provider = MockProvider(chunkSizesSeen: .init())
    // Second chunk (w4,w5,w6) contains a poison lemma and will throw.
    let lemmas = ["w1", "w2", "w3", "!bad", "w5", "w6", "w7"]

    let outcome = await provider.generateCards(lemmas: lemmas, language: .english, literaryExamples: false, chunkSize: 3)

    #expect(outcome.failures.count == 1)
    #expect(outcome.cards.map(\.lemma) == ["w1", "w2", "w3", "w7"])   // chunks 1 and 3 survived
}

@Test("chunkSize below 1 is clamped to 1")
func clampsChunkSize() async {
    let provider = MockProvider(chunkSizesSeen: .init())
    let outcome = await provider.generateCards(lemmas: ["a", "b"], language: .english, literaryExamples: false, chunkSize: 0)
    #expect(outcome.cards.count == 2)
}
