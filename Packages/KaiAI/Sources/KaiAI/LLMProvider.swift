import Foundation
import KaiCore

/// Provider-agnostic AI operations. Concrete providers talk to a specific backend.
public protocol LLMProvider: Sendable {
    /// Generates structured cards for the given lemmas in the target language.
    func generateCards(lemmas: [String], language: LanguageDomain, literaryExamples: Bool) async throws -> [GeneratedCard]

    /// Generates a short study passage that uses the given words, plus a translation.
    func generateStory(words: [String], language: LanguageDomain) async throws -> GeneratedStory
}
