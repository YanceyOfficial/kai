import Foundation

/// One example sentence with its translation, as produced by the model.
public struct GeneratedExample: Codable, Equatable, Sendable {
    public let sentence: String
    public let translation: String
}

/// One quiz item. `type` is the raw value of a KaiCore `QuizType`; validated at ingestion.
public struct GeneratedQuiz: Codable, Equatable, Sendable {
    public let type: String
    public let question: String
    public let choices: [String]
    public let answers: [String]
    public let translation: String
}

/// A full vocabulary card produced by the model, before it is mapped to a KaiCore entry.
public struct GeneratedCard: Codable, Equatable, Sendable {
    public let lemma: String
    public let kind: String
    public let phonetic: String
    public let syllables: [String]
    public let explanation: String
    public let partsOfSpeech: [String]
    public let examples: [GeneratedExample]
    public let mnemonic: String
    public let etymology: String
    public let synonyms: [String]
    public let confusables: [String]
    public let quizzes: [GeneratedQuiz]
}

/// The top-level object returned by structured-output generation (a schema must be an object).
public struct GeneratedCardBatch: Codable, Equatable, Sendable {
    public let cards: [GeneratedCard]
}
