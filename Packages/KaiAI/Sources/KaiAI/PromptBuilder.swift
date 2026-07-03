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
    /// Explanatory glosses are written in the learner's native language (Chinese) while
    /// the target-language content (the word, examples, synonyms, collocation phrases)
    /// stays in \(languageName).
    public func systemPrompt() -> String {
        var lines = [
            "You are a lexicographer generating study flashcards for \(languageName) vocabulary, aimed at native Chinese speakers.",
            "Write `explanation` as a CONCISE CHINESE gloss: part of speech + short meaning, like a dictionary headword (e.g. \"vt. 保证；使确信\"). Keep it short — it is used as a quiz option.",
            "Write `explanationEn` as a fuller \(languageName) definition (\(languageName)-to-\(languageName) study). If you have none, return an empty string.",
            "Also produce: phonetic notation, syllable breakdown, parts of speech, at least 3 example sentences (each `sentence` in \(languageName) with a Chinese `translation`), a memorable mnemonic (in Chinese), a brief etymology (in Chinese), and easily-confused words.",
            "For `synonyms`, group similar words BY SENSE like a bilingual dictionary: each group has `sense` (the shared meaning, in CHINESE) and `words` (the \(languageName) words carrying that sense). Use a separate group per distinct meaning.",
            "Produce a `roots` morpheme analysis: break the word into prefix/root/suffix, keeping the \(languageName) morpheme forms but giving each part's meaning IN CHINESE (e.g. \"ec-（出）+ centr（中心）+ -ic → 偏离中心\"). If the word has no identifiable roots, return an empty string for `roots`.",
            "Produce `collocations`: fixed collocations / common phrases the word forms (e.g. for \"use\": \"used to\", \"make use of\"). Each has `phrase` (\(languageName)), `meaning` (Chinese gloss), `example` (one \(languageName) sentence) and `exampleTranslation` (its Chinese translation). Return an empty array if the word forms no notable collocations.",
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
