import Foundation

/// A cluster of similar words sharing one sense, grouped like a bilingual dictionary:
/// `sense` is the shared meaning, `words` are the words that carry it. Embedded as a
/// Codable value type in entries.
public struct SynonymGroup: Codable, Hashable, Sendable {
    public var sense: String
    public var words: [String]

    public init(sense: String, words: [String]) {
        self.sense = sense
        self.words = words
    }
}
