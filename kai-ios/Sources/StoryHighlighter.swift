import Foundation

/// Splits story text into segments so the view can highlight and link the target words.
/// Pure and testable — no SwiftUI. The view maps segments to styled/linked runs.
enum StoryHighlighter {
    struct Segment: Equatable {
        let text: String
        /// The canonical (lowercased) lemma when this segment is a target word; else nil.
        let lemma: String?
    }

    /// Tokenizes `text` into runs of letters and non-letters, marking each letter run that
    /// matches one of `words` (case-insensitive, whole word) with its lowercased lemma.
    /// Concatenating the segments' `text` reproduces the input exactly.
    static func segments(text: String, words: [String]) -> [Segment] {
        let targets = Set(words.map { $0.lowercased() })
        guard !targets.isEmpty, !text.isEmpty else {
            return text.isEmpty ? [] : [Segment(text: text, lemma: nil)]
        }

        var segments: [Segment] = []
        var current = ""
        var currentIsLetter: Bool?

        func flush() {
            guard !current.isEmpty else { return }
            let lower = current.lowercased()
            let isWord = currentIsLetter == true && targets.contains(lower)
            segments.append(Segment(text: current, lemma: isWord ? lower : nil))
            current = ""
        }

        for ch in text {
            let isLetter = ch.isLetter
            if currentIsLetter == nil || isLetter == currentIsLetter {
                current.append(ch)
            } else {
                flush()
                current.append(ch)
            }
            currentIsLetter = isLetter
        }
        flush()
        return segments
    }
}
