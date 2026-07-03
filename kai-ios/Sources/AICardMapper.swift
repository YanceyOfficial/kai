import Foundation
import KaiCore
import KaiAI

/// Maps a model-generated card into a persistable `VocabularyEntry`. Pure and
/// testable; empty optional-ish fields become `nil` rather than empty strings.
enum AICardMapper {
    static func entry(from card: GeneratedCard, language: LanguageDomain = .english, now: Date = .now) -> VocabularyEntry {
        VocabularyEntry(
            lemma: card.lemma,
            kind: EntryKind(rawValue: card.kind) ?? .word,
            language: language,
            phonetic: card.phonetic,
            syllables: card.syllables,
            explanation: card.explanation,
            partsOfSpeech: card.partsOfSpeech,
            examples: card.examples.map { Example(sentence: $0.sentence, translation: $0.translation) },
            mnemonic: card.mnemonic.isEmpty ? nil : card.mnemonic,
            etymology: card.etymology.isEmpty ? nil : card.etymology,
            synonyms: card.synonyms,
            confusables: card.confusables,
            source: .single,
            now: now
        )
    }
}
