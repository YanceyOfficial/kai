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
          "explanationEn": "odd or unconventional",
          "partsOfSpeech": ["adj."],
          "examples": [{"sentence": "He is eccentric.", "translation": "他很古怪。"}],
          "mnemonic": "ec-centric", "etymology": "from Greek",
          "roots": "ec- (out) + centr (center)",
          "synonyms": [{"sense": "古怪的", "words": ["odd", "quirky"]}],
          "collocations": [{"phrase": "an eccentric habit", "meaning": "古怪的习惯",
            "example": "He has an eccentric habit.", "exampleTranslation": "他有个古怪的习惯。"}],
          "confusables": ["erratic"], "quizzes": []
        }
        """)
        let entry = AICardMapper.entry(from: generated)
        #expect(entry.lemma == "eccentric")
        #expect(entry.kind == .word)
        #expect(entry.phonetic == "/ɪkˈsɛntrɪk/")
        #expect(entry.explanation == "adj. 古怪的")
        #expect(entry.explanationEn == "odd or unconventional")
        #expect(entry.examples.first?.sentence == "He is eccentric.")
        #expect(entry.examples.first?.translation == "他很古怪。")
        #expect(entry.mnemonic == "ec-centric")
        #expect(entry.etymology == "from Greek")
        #expect(entry.roots == "ec- (out) + centr (center)")
        #expect(entry.synonymGroups.first?.sense == "古怪的")
        #expect(entry.synonymGroups.first?.words == ["odd", "quirky"])
        #expect(entry.collocations.first?.phrase == "an eccentric habit")
        #expect(entry.collocations.first?.meaning == "古怪的习惯")
        #expect(entry.collocations.first?.exampleTranslation == "他有个古怪的习惯。")
        #expect(entry.language == .english)
    }

    @Test("Empty mnemonic/etymology become nil")
    func emptyOptionalsBecomeNil() throws {
        let generated = try card(json: """
        {
          "lemma": "obsession", "kind": "word", "phonetic": "",
          "syllables": [], "explanation": "n. 痴迷", "explanationEn": "",
          "partsOfSpeech": [], "examples": [], "mnemonic": "", "etymology": "",
          "roots": "", "synonyms": [], "collocations": [],
          "confusables": [], "quizzes": []
        }
        """)
        let entry = AICardMapper.entry(from: generated)
        #expect(entry.explanationEn == nil)
        #expect(entry.mnemonic == nil)
        #expect(entry.etymology == nil)
        #expect(entry.roots == nil)
        #expect(entry.synonymGroups.isEmpty)
        #expect(entry.collocations.isEmpty)
        #expect(entry.examples.isEmpty)
    }

    @Test("Source defaults to single and can be overridden (e.g. OCR)")
    func sourceTagging() throws {
        let generated = try card(json: """
        {
          "lemma": "x", "kind": "word", "phonetic": "", "syllables": [],
          "explanation": "", "explanationEn": "", "partsOfSpeech": [], "examples": [],
          "mnemonic": "", "etymology": "", "roots": "", "synonyms": [],
          "collocations": [], "confusables": [], "quizzes": []
        }
        """)
        #expect(AICardMapper.entry(from: generated).source == .single)
        #expect(AICardMapper.entry(from: generated, source: .ocr).source == .ocr)
    }
}
