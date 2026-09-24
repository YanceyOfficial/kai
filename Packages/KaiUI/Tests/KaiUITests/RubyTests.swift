import Testing
@testable import KaiUI

@Test("Markup splits into plain runs and annotated bases, in order")
func rubyParse() {
    #expect(Ruby.parse("{曖昧|あいまい}な{返事|へんじ}") == [
        .ruby(base: "曖昧", reading: "あいまい"),
        .text("な"),
        .ruby(base: "返事", reading: "へんじ"),
    ])
    #expect(Ruby.parse("plain English") == [.text("plain English")])
    #expect(Ruby.parse("") == [])
}

@Test("A full-width bar separates base and reading too")
func rubyFullWidthBar() {
    #expect(Ruby.parse("{漢字｜かんじ}") == [.ruby(base: "漢字", reading: "かんじ")])
}

@Test("Braces that are not an annotation stay as literal text")
func rubyMalformed() {
    #expect(Ruby.plain("a {b} c") == "a {b} c")
    #expect(Ruby.plain("{|x} {y|} {open") == "{|x} {y|} {open")
    #expect(Ruby.plain("{{漢|かん}") == "{漢")
    #expect(!Ruby.hasRuby("a {b} c"))
}

@Test("Plain drops readings; reading replaces bases with them")
func rubyPlainAndReading() {
    let markup = "{曖昧|あいまい}な{返事|へんじ}をする"
    #expect(Ruby.plain(markup) == "曖昧な返事をする")
    #expect(Ruby.reading(markup) == "あいまいなへんじをする")
    #expect(Ruby.hasRuby(markup))
}
