import Testing
@testable import kai_ios

@Suite("StoryHighlighter")
struct StoryHighlighterTests {
    @Test("Marks whole-word, case-insensitive matches and preserves the text")
    func marksWords() {
        let segs = StoryHighlighter.segments(text: "He is Eccentric, truly.", words: ["eccentric"])
        // Reassembly is lossless.
        #expect(segs.map(\.text).joined() == "He is Eccentric, truly.")
        // The matched word carries its lowercased lemma; nothing else does.
        let marked = segs.filter { $0.lemma != nil }
        #expect(marked.count == 1)
        #expect(marked.first?.text == "Eccentric")
        #expect(marked.first?.lemma == "eccentric")
    }

    @Test("Does not match substrings inside longer words")
    func noSubstringMatch() {
        let segs = StoryHighlighter.segments(text: "authentication", words: ["the"])
        #expect(segs.allSatisfy { $0.lemma == nil })
    }

    @Test("Empty word list leaves the text as a single plain segment")
    func noTargets() {
        let segs = StoryHighlighter.segments(text: "plain text", words: [])
        #expect(segs == [StoryHighlighter.Segment(text: "plain text", lemma: nil)])
    }
}
