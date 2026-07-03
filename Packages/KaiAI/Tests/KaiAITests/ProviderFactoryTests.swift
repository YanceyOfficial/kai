import Foundation
import Testing
import KaiCore
@testable import KaiAI

private final class OKTransport: HTTPTransport, @unchecked Sendable {
    let body: Data
    init(_ body: Data) { self.body = body }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        (body, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

@Test("Factory builds a Claude provider that works end-to-end through a stub transport")
func factoryClaude() async throws {
    let inner = #"{"cards":[{"lemma":"x","kind":"word","phonetic":"","syllables":[],"explanation":"","explanationEn":"","partsOfSpeech":[],"examples":[],"mnemonic":"","etymology":"","synonyms":[],"collocations":[],"confusables":[],"quizzes":[]}]}"#
    let env = try JSONSerialization.data(withJSONObject: ["content": [["type": "text", "text": inner]]])
    let config = AIConfiguration(kind: .claude, apiKey: "k", model: nil)
    let provider = ProviderFactory.make(config, transport: OKTransport(env))
    let cards = try await provider.generateCards(lemmas: ["x"], language: .english, literaryExamples: false)
    #expect(cards.first?.lemma == "x")
}

@Test("Factory selects OpenAI when configured")
func factoryOpenAI() async throws {
    let inner = #"{"cards":[]}"#
    let env = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": inner]]]])
    let config = AIConfiguration(kind: .openai, apiKey: "k", model: "gpt-5.5")
    let provider = ProviderFactory.make(config, transport: OKTransport(env))
    let cards = try await provider.generateCards(lemmas: [], language: .english, literaryExamples: false)
    #expect(cards.isEmpty)
}
