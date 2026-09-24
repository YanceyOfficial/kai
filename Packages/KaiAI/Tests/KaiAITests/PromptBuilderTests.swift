import Testing
import KaiCore
@testable import KaiAI

@Test("System prompt states the word-vs-phrase quiz rule and target language")
func systemPromptRules() {
    let p = PromptBuilder(language: .english, literaryExamples: false)
    let s = p.systemPrompt()
    #expect(s.contains("English"))
    #expect(s.lowercased().contains("phrase"))       // must mention the phrase handling
    #expect(s.contains("splitCombine"))              // must name the syllable quiz type
}

@Test("Literary flag toggles the example-style instruction")
func literaryFlag() {
    let plain = PromptBuilder(language: .english, literaryExamples: false).systemPrompt()
    let literary = PromptBuilder(language: .english, literaryExamples: true).systemPrompt()
    #expect(!plain.lowercased().contains("literary"))
    #expect(literary.lowercased().contains("literary"))
}

@Test("User prompt lists the requested lemmas")
func userPromptListsLemmas() {
    let p = PromptBuilder(language: .english, literaryExamples: false)
    let u = p.cardUserPrompt(lemmas: ["eccentric", "obsession"])
    #expect(u.contains("eccentric"))
    #expect(u.contains("obsession"))
}

@Test("Japanese cards ask for ruby markup, a kana reading with pitch accent, and a kanji breakdown")
func japaneseSystemPrompt() {
    let s = PromptBuilder(language: .japanese, literaryExamples: false).systemPrompt()
    #expect(s.contains("Japanese"))
    #expect(s.contains("{勉強|べんきょう}"))           // the markup the app parses, by example
    #expect(s.contains("{食|た}べる"))                // okurigana outside the braces
    #expect(s.contains("pitch accent"))
    #expect(s.contains("kanji breakdown"))
    #expect(s.contains("never with ruby markup"))     // the lemma stays plain
    #expect(s.contains("Never emit splitCombine"))
    #expect(!s.contains("English words"))
}

@Test("English cards are untouched by the Japanese rules")
func englishPromptHasNoRuby() {
    let s = PromptBuilder(language: .english, literaryExamples: false).systemPrompt()
    #expect(!s.contains("RUBY MARKUP"))
    #expect(!s.contains("{"))
}

@Test("The Japanese story is written in Japanese with ruby markup")
func japaneseStoryPrompt() {
    let s = PromptBuilder(language: .japanese, literaryExamples: false).storySystemPrompt()
    #expect(s.contains("Japanese passage"))
    #expect(s.contains("RUBY MARKUP"))
    #expect(s.lowercased().contains("chinese translation"))
}
