import Foundation
import KaiCore

/// Builds prompts for card generation. Encodes the word/phrase rule and the literary-example option.
public struct PromptBuilder: Sendable {
    private let language: LanguageDomain
    private let literaryExamples: Bool

    public init(language: LanguageDomain, literaryExamples: Bool) {
        self.language = language
        self.literaryExamples = literaryExamples
    }

    private var languageName: String {
        switch language {
        case .english: return "English"
        case .japanese: return "Japanese"
        }
    }

    /// The system prompt: role, per-field expectations, and the word/phrase quiz rule.
    public func systemPrompt() -> String {
        var lines = [
            "You are a lexicographer generating study flashcards for \(languageName) vocabulary.",
            "For each item produce: a concise explanation, phonetic notation, syllable breakdown, parts of speech, at least 3 example sentences (each with a translation), a memorable mnemonic, a brief etymology, synonyms, and easily-confused words.",
            "Also produce at least 3 quiz items. Quiz `type` must be one of: singleChoice, splitCombine, fillInBlank, listeningSpelling, meaningMatch, contextCloze.",
            "IMPORTANT: if an item is a multi-word phrase, set its kind to \"phrase\" and DO NOT emit splitCombine or listeningSpelling quizzes for it (those apply to single words only). Single words use kind \"word\".",
        ]
        if literaryExamples {
            lines.append("Prefer example sentences written in a literary style, evoking passages from classic literature, while remaining natural.")
        }
        return lines.joined(separator: "\n")
    }

    /// The user prompt listing the lemmas to generate cards for.
    public func cardUserPrompt(lemmas: [String]) -> String {
        let cleaned = lemmas.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return "Generate cards for these items:\n" + cleaned.map { "- \($0)" }.joined(separator: "\n")
    }
}
