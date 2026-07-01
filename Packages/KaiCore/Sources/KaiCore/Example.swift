import Foundation

/// A single example sentence: English original + Chinese translation + source style. Embedded as a Codable value type in entries.
public struct Example: Codable, Hashable, Sendable {
    public var sentence: String
    public var translation: String
    public var source: ExampleSource

    public init(sentence: String, translation: String, source: ExampleSource = .plain) {
        self.sentence = sentence
        self.translation = translation
        self.source = source
    }
}
