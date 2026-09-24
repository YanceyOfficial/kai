import Foundation
import KaiCore
import KaiAI
import KaiUI

/// Maps a model-generated card into a persistable `VocabularyEntry`. Pure and
/// testable; empty optional-ish fields become `nil` rather than empty strings.
///
/// Ruby markup (`{漢字|かんじ}`) belongs in Japanese sentences only. Fields that are
/// looked up, matched or compared — the lemma, related words, quiz choices and answers
/// — are stripped to plain text in case a model annotated them anyway.
enum AICardMapper {
    static func entry(from card: GeneratedCard, language: LanguageDomain = .english, source: EntrySource = .single, now: Date = .now) -> VocabularyEntry {
        VocabularyEntry(
            lemma: Ruby.plain(card.lemma),
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
            synonymGroups: card.synonyms.map { SynonymGroup(sense: $0.sense, words: $0.words.map(Ruby.plain)) },
            collocations: card.collocations.map {
                Collocation(phrase: $0.phrase, meaning: $0.meaning, example: $0.example, exampleTranslation: $0.exampleTranslation)
            },
            quizzes: card.quizzes.compactMap { quiz in
                guard let type = QuizType(rawValue: quiz.type) else { return nil }   // drop unknown types
                return Quiz(type: type, question: quiz.question, choices: quiz.choices.map(Ruby.plain),
                            answers: quiz.answers.map(Ruby.plain), translation: quiz.translation)
            },
            confusables: card.confusables.map(Ruby.plain),
            source: source,
            now: now
        )
    }
}
