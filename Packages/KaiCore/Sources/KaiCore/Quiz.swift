import Foundation

/// A quiz item attached to an entry (produced by AI generation). `type` selects the
/// format; an empty `choices` means the answer is typed. `answers` are the accepted
/// correct responses. Embedded as a Codable value type in entries.
public struct Quiz: Codable, Hashable, Sendable {
    public var type: QuizType
    public var question: String
    public var choices: [String]
    public var answers: [String]
    public var translation: String

    public init(
        type: QuizType,
        question: String,
        choices: [String] = [],
        answers: [String] = [],
        translation: String = ""
    ) {
        self.type = type
        self.question = question
        self.choices = choices
        self.answers = answers
        self.translation = translation
    }
}
