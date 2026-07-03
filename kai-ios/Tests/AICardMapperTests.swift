import Testing
import Foundation
@testable import kai_ios
import KaiAI
import KaiCore

@Suite("AICardMapper")
struct AICardMapperTests {
    // GeneratedCard's memberwise init is internal to KaiAI, so build one via its
    // Codable conformance (the same path the providers use).
    private func card(json: String) throws -> GeneratedCard {
        try JSONDecoder().decode(GeneratedCard.self, from: Data(json.utf8))
    }

    @Test("Maps model fields onto a VocabularyEntry")
    func mapsFields() throws {
        let generated = try card(json: """
        {
          "lemma": "eccentric", "kind": "word", "phonetic": "/ɪkˈsɛntrɪk/",
          "syllables": ["ec","cen","tric"], "explanation": "adj. 古怪的",
          "partsOfSpeech": ["adj."],
          "examples": [{"sentence": "He is eccentric.", "translation": "他很古怪。"}],
          "mnemonic": "ec-centric", "etymology": "from Greek", "synonyms": ["odd"],
          "confusables": ["erratic"], "quizzes": []
        }
        """)
        let entry = AICardMapper.entry(from: generated)
        #expect(entry.lemma == "eccentric")
        #expect(entry.kind == .word)
        #expect(entry.phonetic == "/ɪkˈsɛntrɪk/")
        #expect(entry.explanation == "adj. 古怪的")
        #expect(entry.examples.first?.sentence == "He is eccentric.")
        #expect(entry.examples.first?.translation == "他很古怪。")
        #expect(entry.mnemonic == "ec-centric")
        #expect(entry.etymology == "from Greek")
        #expect(entry.synonyms == ["odd"])
        #expect(entry.language == .english)
    }

    @Test("Empty mnemonic/etymology become nil")
    func emptyOptionalsBecomeNil() throws {
        let generated = try card(json: """
        {
          "lemma": "obsession", "kind": "word", "phonetic": "",
          "syllables": [], "explanation": "n. 痴迷", "partsOfSpeech": [],
          "examples": [], "mnemonic": "", "etymology": "", "synonyms": [],
          "confusables": [], "quizzes": []
        }
        """)
        let entry = AICardMapper.entry(from: generated)
        #expect(entry.mnemonic == nil)
        #expect(entry.etymology == nil)
        #expect(entry.examples.isEmpty)
    }
}
