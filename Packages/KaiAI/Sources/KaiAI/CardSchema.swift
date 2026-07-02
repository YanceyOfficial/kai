import Foundation

/// The provider-agnostic JSON schema for structured card generation, matching `GeneratedCardBatch`.
public enum CardSchema {
    private static var example: JSONSchema {
        .object(["sentence": .string, "translation": .string], required: ["sentence", "translation"])
    }
    private static var quiz: JSONSchema {
        .object([
            "type": .string, "question": .string, "choices": .array(.string),
            "answers": .array(.string), "translation": .string,
        ], required: ["type", "question", "choices", "answers", "translation"])
    }
    private static var card: JSONSchema {
        .object([
            "lemma": .string,
            "kind": .stringEnum(["word", "phrase"]),
            "phonetic": .string,
            "syllables": .array(.string),
            "explanation": .string,
            "partsOfSpeech": .array(.string),
            "examples": .array(example),
            "mnemonic": .string,
            "etymology": .string,
            "synonyms": .array(.string),
            "confusables": .array(.string),
            "quizzes": .array(quiz),
        ], required: [
            "lemma", "kind", "phonetic", "syllables", "explanation", "partsOfSpeech",
            "examples", "mnemonic", "etymology", "synonyms", "confusables", "quizzes",
        ])
    }

    /// Top-level schema: an object with a `cards` array.
    public static var cardBatch: JSONSchema {
        .object(["cards": .array(card)], required: ["cards"])
    }
}
