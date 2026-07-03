import Foundation
import Testing
@testable import KaiAI

@Test("A generated card batch decodes from the provider JSON contract")
func decodeCardBatch() throws {
    let json = """
    {"cards":[{"lemma":"eccentric","kind":"word","phonetic":"/ɪkˈsɛntrɪk/",
    "syllables":["ec","cen","tric"],"explanation":"adj. 古怪的，异乎寻常的",
    "explanationEn":"odd or unconventional in behaviour",
    "partsOfSpeech":["adjective","noun"],
    "examples":[{"sentence":"He is eccentric.","translation":"他很古怪。"}],
    "mnemonic":"ex-center：偏离中心","etymology":"源自希腊语 ekkentros",
    "roots":"ec-（出）+ centr（中心）+ -ic",
    "synonyms":[{"sense":"古怪的","words":["quirky","odd"]}],
    "collocations":[{"phrase":"an eccentric habit","meaning":"古怪的习惯",
    "example":"He has an eccentric habit.","exampleTranslation":"他有个古怪的习惯。"}],
    "confusables":["erratic"],
    "quizzes":[{"type":"singleChoice","question":"They are the ____ of this world.",
    "choices":["eccentrics","workers"],"answers":["eccentrics"],"translation":"..."}]}]}
    """.data(using: .utf8)!
    let batch = try JSONDecoder().decode(GeneratedCardBatch.self, from: json)
    #expect(batch.cards.count == 1)
    let card = batch.cards[0]
    #expect(card.lemma == "eccentric")
    #expect(card.kind == "word")
    #expect(card.explanation == "adj. 古怪的，异乎寻常的")
    #expect(card.explanationEn == "odd or unconventional in behaviour")
    #expect(card.examples.first?.translation == "他很古怪。")
    #expect(card.roots == "ec-（出）+ centr（中心）+ -ic")
    #expect(card.synonyms.first?.sense == "古怪的")
    #expect(card.synonyms.first?.words == ["quirky", "odd"])
    #expect(card.collocations.first?.phrase == "an eccentric habit")
    #expect(card.collocations.first?.exampleTranslation == "他有个古怪的习惯。")
    #expect(card.quizzes.first?.answers == ["eccentrics"])
}

@Test("Roots is optional — a card without it decodes with roots == nil")
func rootsOptional() throws {
    let json = """
    {"cards":[{"lemma":"x","kind":"word","phonetic":"","syllables":[],"explanation":"",
    "explanationEn":"","partsOfSpeech":[],"examples":[],"mnemonic":"","etymology":"",
    "synonyms":[],"collocations":[],"confusables":[],"quizzes":[]}]}
    """.data(using: .utf8)!
    let batch = try JSONDecoder().decode(GeneratedCardBatch.self, from: json)
    #expect(batch.cards[0].roots == nil)
}
