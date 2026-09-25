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

/// Answers with the body of the first route whose fragment the URL contains — list the
/// most specific first (a paged request's URL contains both "after_id" and "/v1/models").
private final class JSONTransport: HTTPTransport, @unchecked Sendable {
    let routes: [(fragment: String, body: Data)]
    private(set) var requests: [URLRequest] = []
    init(_ routes: [(fragment: String, body: Data)]) { self.routes = routes }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let body = routes.first { request.url!.absoluteString.contains($0.fragment) }?.body ?? Data()
        return (body, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

@Test("Anthropic's model list pages through after_id and keeps each model's output ceiling")
func anthropicModelList() async throws {
    let first = try JSONSerialization.data(withJSONObject: [
        "data": [["id": "claude-opus-5-5", "display_name": "Claude Opus 5.5", "max_tokens": 128000]],
        "has_more": true, "last_id": "claude-opus-5-5"])
    let second = try JSONSerialization.data(withJSONObject: [
        "data": [["id": "claude-haiku-4-5", "display_name": "Claude Haiku 4.5", "max_tokens": 64000]],
        "has_more": false, "last_id": "claude-haiku-4-5"])
    let transport = JSONTransport([("after_id", second), ("/v1/models", first)])
    let models = try await ModelListing.models(for: .claude, apiKey: "k", transport: transport)
    #expect(models.map(\.id) == ["claude-opus-5-5", "claude-haiku-4-5"])
    #expect(models.first?.maxOutputTokens == 128000)
    #expect(transport.requests.first?.value(forHTTPHeaderField: "x-api-key") == "k")
}

@Test("OpenAI's model list keeps chat models only, newest first")
func openAIModelList() async throws {
    let body = try JSONSerialization.data(withJSONObject: ["data": [
        ["id": "gpt-5", "created": 100], ["id": "text-embedding-3-large", "created": 300],
        ["id": "gpt-5.5", "created": 200], ["id": "gpt-4o-realtime-preview", "created": 250],
        ["id": "o3", "created": 150], ["id": "whisper-1", "created": 50],
    ]])
    let models = try await ModelListing.models(for: .openai, apiKey: "k", transport: JSONTransport([("/v1/models", body)]))
    #expect(models.map(\.id) == ["gpt-5.5", "o3", "gpt-5"])
    #expect(models.allSatisfy { $0.maxOutputTokens == nil })
}

@Test("A refused key fails the model list with a readable error")
func refusedKey() async {
    final class Refusing: HTTPTransport, @unchecked Sendable {
        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            (Data("invalid x-api-key".utf8), HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!)
        }
    }
    do {
        _ = try await ModelListing.models(for: .claude, apiKey: "bad", transport: Refusing())
        Issue.record("expected a failure")
    } catch {
        #expect(error.localizedDescription.contains("refused"))
    }
}

@Test("The factory passes the model's output ceiling through as max_tokens")
func factoryUsesModelCeiling() async throws {
    let inner = #"{"cards":[]}"#
    let env = try JSONSerialization.data(withJSONObject: ["content": [["type": "text", "text": inner]]])
    let transport = JSONTransport([("messages", env)])
    let config = AIConfiguration(kind: .claude, apiKey: "k", model: "claude-opus-5-5", maxOutputTokens: 128000)
    _ = try await ProviderFactory.make(config, transport: transport).generateCards(lemmas: ["x"], language: .english, literaryExamples: false)
    let body = try #require(transport.requests.first?.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["max_tokens"] as? Int == 128000)
    #expect(transport.requests.first?.timeoutInterval == 600)
}
