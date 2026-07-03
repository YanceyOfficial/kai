import Testing
@testable import kai_ios

@Suite("PastedWordsParser")
struct PastedWordsParserTests {
    @Test("Splits lines, trims, and drops blanks")
    func splitsAndTrims() {
        let words = PastedWordsParser.lemmas(from: "  eccentric \n\nobsession\n   \nmeticulous")
        #expect(words == ["eccentric", "obsession", "meticulous"])
    }

    @Test("Dedupes case-insensitively, keeping the first spelling")
    func dedupes() {
        let words = PastedWordsParser.lemmas(from: "Apple\napple\nAPPLE\nBanana")
        #expect(words == ["Apple", "Banana"])
    }

    @Test("Empty or whitespace-only text yields no words")
    func empty() {
        #expect(PastedWordsParser.lemmas(from: "   \n\n ").isEmpty)
        #expect(PastedWordsParser.lemmas(from: "").isEmpty)
    }
}
