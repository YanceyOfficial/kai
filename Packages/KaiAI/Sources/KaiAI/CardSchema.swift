import Foundation

/// The provider-agnostic JSON schema for structured card generation, matching `GeneratedCardBatch`.
public enum CardSchema {
    private static var example: JSONSchema {
        .object(["sentence": .string, "translation": .string], required: ["sentence", "translation"])
    }
    private static var synonymGroup: JSONSchema {
        .object(["sense": .string, "words": .array(.string)], required: ["sense", "words"])
    }
    private static var collocation: JSONSchema {
        .object([
            "phrase": .string, "meaning": .string,
            "example": .string, "exampleTranslation": .string,
        ], required: ["phrase", "meaning", "example", "exampleTranslation"])
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
            "explanationEn": .string,
            "partsOfSpeech": .array(.string),
            "examples": .array(example),
            "mnemonic": .string,
            "etymology": .string,
            "roots": .string,
            "synonyms": .array(synonymGroup),
            "collocations": .array(collocation),
            "confusables": .array(.string),
            "quizzes": .array(quiz),
        ], required: [
            // All properties are required (OpenAI strict mode); the model returns an empty
            // string for optional-in-practice fields (`roots`, `explanationEn`).
            "lemma", "kind", "phonetic", "syllables", "explanation", "explanationEn",
            "partsOfSpeech", "examples", "mnemonic", "etymology", "roots", "synonyms",
            "collocations", "confusables", "quizzes",
        ])
    }

    /// Top-level schema: an object with a `cards` array.
    public static var cardBatch: JSONSchema {
        .object(["cards": .array(card)], required: ["cards"])
    }
}
