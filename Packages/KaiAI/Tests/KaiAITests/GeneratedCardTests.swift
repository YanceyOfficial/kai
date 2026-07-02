import Foundation
import Testing
@testable import KaiAI

@Test("A generated card batch decodes from the provider JSON contract")
func decodeCardBatch() throws {
    let json = """
    {"cards":[{"lemma":"eccentric","kind":"word","phonetic":"/ɪkˈsɛntrɪk/",
    "syllables":["ec","cen","tric"],"explanation":"adj. odd or unconventional",
    "partsOfSpeech":["adjective","noun"],
    "examples":[{"sentence":"He is eccentric.","translation":"He is unconventional."}],
    "mnemonic":"ex-center: off-center behaviour","etymology":"from Greek ekkentros",
    "synonyms":["quirky"],"confusables":["erratic"],
    "quizzes":[{"type":"singleChoice","question":"They are the ____ of this world.",
    "choices":["eccentrics","workers"],"answers":["eccentrics"],"translation":"..."}]}]}
    """.data(using: .utf8)!
    let batch = try JSONDecoder().decode(GeneratedCardBatch.self, from: json)
    #expect(batch.cards.count == 1)
    let card = batch.cards[0]
    #expect(card.lemma == "eccentric")
    #expect(card.kind == "word")
    #expect(card.examples.first?.translation == "He is unconventional.")
    #expect(card.quizzes.first?.answers == ["eccentrics"])
}
