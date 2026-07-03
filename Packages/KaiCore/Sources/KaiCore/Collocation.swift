import Foundation

/// A fixed collocation or phrase a word commonly forms (e.g. `use` → `make use of`).
/// `phrase` and `example` are English; `meaning` and `exampleTranslation` are the
/// learner's native-language (Chinese) glosses. Embedded as a Codable value type.
public struct Collocation: Codable, Hashable, Sendable {
    /// The collocation itself, e.g. "make use of".
    public var phrase: String
    /// Chinese gloss of the collocation.
    public var meaning: String
    /// English example sentence; empty when none.
    public var example: String
    /// Chinese translation of the example; empty when none.
    public var exampleTranslation: String

    public init(phrase: String, meaning: String, example: String = "", exampleTranslation: String = "") {
        self.phrase = phrase
        self.meaning = meaning
        self.example = example
        self.exampleTranslation = exampleTranslation
    }
}
