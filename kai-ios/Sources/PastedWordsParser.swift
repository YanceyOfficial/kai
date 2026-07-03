import Foundation

/// Parses pasted multi-line text into a clean list of lemmas: one per line, trimmed,
/// blanks dropped, deduped case-insensitively while preserving the first spelling.
/// Pure and testable — the UI just feeds it the text-editor contents.
enum PastedWordsParser {
    static func lemmas(from text: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let lemma = rawLine.trimmingCharacters(in: .whitespaces)
            guard !lemma.isEmpty else { continue }
            let key = lemma.lowercased()
            if seen.insert(key).inserted {
                result.append(lemma)
            }
        }
        return result
    }
}
