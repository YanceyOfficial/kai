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

@Test("Japanese breaks per character, but never inside an annotation")
func rubyUnitsPerCharacter() {
    let units = Ruby.units(Ruby.parse("{返事|へんじ}をする"))
    #expect(units.map { $0.map(\.base).joined() } == ["返事", "を", "す", "る"])
    #expect(units[0] == [Ruby.Part(base: "返事", reading: "へんじ")])
}

@Test("Closing punctuation and small kana never start a line")
func rubyKinsokuClosing() {
    let units = Ruby.units(Ruby.parse("{来|く}た。ちょっと"))
    #expect(units.map { $0.map(\.base).joined() } == ["来", "た。", "ちょっ", "と"])
    // After an annotated base, the punctuation joins its unit as a part of its own.
    let afterRuby = Ruby.units(Ruby.parse("{本|ほん}。"))
    #expect(afterRuby == [[Ruby.Part(base: "本", reading: "ほん"), Ruby.Part(base: "。", reading: nil)]])
}

@Test("Opening brackets never end a line")
func rubyKinsokuOpening() {
    let units = Ruby.units(Ruby.parse("「{本当|ほんとう}？」"))
    #expect(units == [[
        Ruby.Part(base: "「", reading: nil),
        Ruby.Part(base: "本当", reading: "ほんとう"),
        Ruby.Part(base: "？」", reading: nil),
    ]])
}

@Test("Latin words keep their letters and trailing space together")
func rubyUnitsLatin() {
    let units = Ruby.units(Ruby.parse("SNSで{話題|わだい}"))
    #expect(units.map { $0.map(\.base).joined() } == ["SNS", "で", "話題"])
    #expect(Ruby.units(Ruby.parse("an {x|y} word")).map { $0.map(\.base).joined() } == ["an ", "x", " ", "word"])
}

@Test("Units reassemble into the plain text")
func rubyUnitsRoundTrip() {
    let markup = "「{彼|かれ}は{曖昧|あいまい}な{返事|へんじ}しかしなかった。」SNS okだ（{笑|わら}）"
    let joined = Ruby.units(Ruby.parse(markup)).flatMap { $0 }.map(\.base).joined()
    #expect(joined == Ruby.plain(markup))
}

@Test("A reading wider than its base hangs past it, by at most half a character a side")
func rubyHang() {
    // むかし (1.5 em) over 昔 (1 em): a quarter em each side.
    #expect(Ruby.hang(of: Ruby.Part(base: "昔", reading: "むかし"), size: 20) == 5)
    // ほんとう (2 em) over 本当 (2 em): no hang.
    #expect(Ruby.hang(of: Ruby.Part(base: "本当", reading: "ほんとう"), size: 20) == 0)
    // うけたまわる (3 em) over 承 (1 em): capped at half an em each side; the rest widens the part.
    #expect(Ruby.hang(of: Ruby.Part(base: "承", reading: "うけたまわる"), size: 20) == 10)
    #expect(Ruby.hang(of: Ruby.Part(base: "の", reading: nil), size: 20) == 0)
}
