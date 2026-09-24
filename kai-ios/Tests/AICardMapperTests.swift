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
          "confusables": ["erratic"],
          "quizzes": [{"type": "fillInBlank", "question": "He is quite ____.",
            "choices": [], "answers": ["eccentric"], "translation": "他很古怪。"},
            {"type": "bogusType", "question": "x", "choices": [], "answers": ["y"], "translation": ""}]
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
        // Known quiz types map; unknown ("bogusType") is dropped.
        #expect(entry.quizzes.count == 1)
        #expect(entry.quizzes.first?.type == .fillInBlank)
        #expect(entry.quizzes.first?.answers == ["eccentric"])
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

    @Test("Japanese cards keep ruby in sentences but plain text where words are matched")
    func japaneseRuby() throws {
        let generated = try card(json: """
        {
          "lemma": "{懐|なつ}かしい", "kind": "word", "phonetic": "なつかしい ④",
          "syllables": ["な","つ","か","し","い"], "explanation": "[形] 令人怀念的",
          "explanationEn": "", "partsOfSpeech": ["い形容詞"],
          "examples": [{"sentence": "{故郷|ふるさと}の{味|あじ}が{懐|なつ}かしい。", "translation": "怀念故乡的味道。"}],
          "mnemonic": "", "etymology": "", "roots": "",
          "synonyms": [{"sense": "怀念的", "words": ["{恋|こい}しい"]}],
          "collocations": [], "confusables": ["{恋|こい}しい"],
          "quizzes": [{"type": "singleChoice", "question": "{故郷|ふるさと}が＿＿。",
            "choices": ["{懐|なつ}かしい", "{悲|かな}しい"], "answers": ["{懐|なつ}かしい"], "translation": ""}]
        }
        """)
        let entry = AICardMapper.entry(from: generated, language: .japanese)
        #expect(entry.language == .japanese)
        #expect(entry.lemma == "懐かしい")
        #expect(entry.examples.first?.sentence == "{故郷|ふるさと}の{味|あじ}が{懐|なつ}かしい。")
        #expect(entry.synonymGroups.first?.words == ["恋しい"])
        #expect(entry.confusables == ["恋しい"])
        #expect(entry.quizzes.first?.question == "{故郷|ふるさと}が＿＿。")
        #expect(entry.quizzes.first?.choices == ["懐かしい", "悲しい"])
        #expect(entry.quizzes.first?.answers == ["懐かしい"])
    }
}
