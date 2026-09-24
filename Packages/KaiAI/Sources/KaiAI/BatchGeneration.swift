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
    /// `chunkSize`, so a single request can't exceed the model's output budget.
    ///
    /// Up to `concurrency` chunks are in flight at once — a card takes the model tens of
    /// seconds to write, so a batch done one chunk after another took minutes — and
    /// best-effort: a chunk that fails is recorded in `failures` and does not abort the
    /// others, so the user keeps the words that did generate. Card order follows the
    /// input order, whatever order the chunks finish in.
    func generateCards(
        lemmas: [String],
        language: LanguageDomain,
        literaryExamples: Bool,
        chunkSize: Int,
        concurrency: Int = 4
    ) async -> BatchGenerationOutcome {
        let size = max(1, chunkSize)
        let chunks = stride(from: 0, to: lemmas.count, by: size).map {
            Array(lemmas[$0 ..< min($0 + size, lemmas.count)])
        }
        var results = [Result<[GeneratedCard], Error>?](repeating: nil, count: chunks.count)

        await withTaskGroup(of: (Int, Result<[GeneratedCard], Error>).self) { group in
            var next = 0
            func startNext() {
                guard next < chunks.count else { return }
                let index = next
                next += 1
                group.addTask {
                    do {
                        return (index, .success(try await generateCards(
                            lemmas: chunks[index], language: language, literaryExamples: literaryExamples)))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            for _ in 0 ..< max(1, concurrency) { startNext() }
            for await (index, result) in group {
                results[index] = result
                startNext()
            }
        }

        var cards: [GeneratedCard] = []
        var failures: [String] = []
        for result in results {
            switch result {
            case .success(let generated): cards.append(contentsOf: generated)
            case .failure(let error): failures.append(error.localizedDescription)
            case nil: break
            }
        }
        return BatchGenerationOutcome(cards: cards, failures: failures)
    }
}
