import Foundation
import KaiCore
import KaiAI

/// Maps a model-generated card into a persistable `VocabularyEntry`. Pure and
/// testable; empty optional-ish fields become `nil` rather than empty strings.
enum AICardMapper {
    static func entry(from card: GeneratedCard, language: LanguageDomain = .english, source: EntrySource = .single, now: Date = .now) -> VocabularyEntry {
        VocabularyEntry(
            lemma: card.lemma,
            kind: EntryKind(rawValue: card.kind) ?? .word,
            language: language,
            phonetic: card.phonetic,
            syllables: card.syllables,
            explanation: card.explanation,
            explanationEn: card.explanationEn.isEmpty ? nil : card.explanationEn,
            partsOfSpeech: card.partsOfSpeech,
            examples: card.examples.map { Example(sentence: $0.sentence, translation: $0.translation) },
            mnemonic: card.mnemonic.isEmpty ? nil : card.mnemonic,
            etymology: card.etymology.isEmpty ? nil : card.etymology,
            roots: card.roots.flatMap { $0.isEmpty ? nil : $0 },
            synonymGroups: card.synonyms.map { SynonymGroup(sense: $0.sense, words: $0.words) },
            collocations: card.collocations.map {
                Collocation(phrase: $0.phrase, meaning: $0.meaning, example: $0.example, exampleTranslation: $0.exampleTranslation)
            },
            quizzes: card.quizzes.compactMap { quiz in
                guard let type = QuizType(rawValue: quiz.type) else { return nil }   // drop unknown types
                return Quiz(type: type, question: quiz.question, choices: quiz.choices,
                            answers: quiz.answers, translation: quiz.translation)
            },
            confusables: card.confusables,
            source: source,
            now: now
        )
    }
}
