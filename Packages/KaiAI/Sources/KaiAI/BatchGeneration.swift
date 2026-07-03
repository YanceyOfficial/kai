import Foundation
import KaiCore

/// The result of a chunked batch generation: the cards that were produced, plus a
/// message for each chunk that failed (so callers can report partial success).
public struct BatchGenerationOutcome: Sendable {
    public let cards: [GeneratedCard]
    /// One entry per failed chunk (localized error description).
    public let failures: [String]

    public var hasFailures: Bool { !failures.isEmpty }
}

public extension LLMProvider {
    /// Generates cards for many lemmas by splitting them into chunks of at most
    /// `chunkSize`, so a single request can't exceed the model's token budget.
    ///
    /// Chunks run sequentially and best-effort: a chunk that fails is recorded in
    /// `failures` and does not abort the remaining chunks, so the user keeps the words
    /// that did generate. Card order follows the input order.
    func generateCards(
        lemmas: [String],
        language: LanguageDomain,
        literaryExamples: Bool,
        chunkSize: Int
    ) async -> BatchGenerationOutcome {
        let size = max(1, chunkSize)
        var cards: [GeneratedCard] = []
        var failures: [String] = []

        for start in stride(from: 0, to: lemmas.count, by: size) {
            let chunk = Array(lemmas[start ..< min(start + size, lemmas.count)])
            do {
                let generated = try await generateCards(lemmas: chunk, language: language, literaryExamples: literaryExamples)
                cards.append(contentsOf: generated)
            } catch {
                failures.append(error.localizedDescription)
            }
        }
        return BatchGenerationOutcome(cards: cards, failures: failures)
    }
}
