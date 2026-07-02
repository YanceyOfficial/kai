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
