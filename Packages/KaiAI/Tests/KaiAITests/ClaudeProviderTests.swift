import Foundation
import Testing
import KaiCore
@testable import KaiAI

/// Captures the outgoing request and returns a canned Anthropic response body.
private final class CapturingTransport: HTTPTransport, @unchecked Sendable {
    let responseBody: Data
    private(set) var lastRequest: URLRequest?
    init(responseBody: Data) { self.responseBody = responseBody }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (responseBody, resp)
    }
}

private let anthropicBody: Data = {
    // Anthropic wraps the JSON string in content[0].text.
    let inner = #"{"cards":[{"lemma":"eccentric","kind":"word","phonetic":"/x/","syllables":["ec"],"explanation":"odd","partsOfSpeech":["adjective"],"examples":[{"sentence":"a","translation":"b"}],"mnemonic":"m","etymology":"e","synonyms":[],"confusables":[],"quizzes":[]}]}"#
    let envelope: [String: Any] = ["content": [["type": "text", "text": inner]], "stop_reason": "end_turn"]
    return try! JSONSerialization.data(withJSONObject: envelope)
}()

@Test("ClaudeProvider builds a correct Messages request and decodes cards")
func claudeGenerateCards() async throws {
    let transport = CapturingTransport(responseBody: anthropicBody)
    let provider = ClaudeProvider(apiKey: "sk-test", model: "claude-opus-4-8", transport: transport)
    let cards = try await provider.generateCards(lemmas: ["eccentric"], language: .english, literaryExamples: false)

    #expect(cards.count == 1)
    #expect(cards[0].lemma == "eccentric")

    let req = try #require(transport.lastRequest)
    #expect(req.url?.absoluteString == "https://api.anthropic.com/v1/messages")
    #expect(req.httpMethod == "POST")
    #expect(req.value(forHTTPHeaderField: "x-api-key") == "sk-test")
    #expect(req.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")

    let body = try #require(req.httpBody)
    let obj = try JSONSerialization.jsonObject(with: body) as! [String: Any]
    #expect(obj["model"] as? String == "claude-opus-4-8")
    let outputConfig = obj["output_config"] as! [String: Any]
    let format = outputConfig["format"] as! [String: Any]
    #expect(format["type"] as? String == "json_schema")
    #expect(format["schema"] != nil)
}

@Test("ClaudeProvider maps non-2xx to AIError.http")
func claudeHTTPError() async throws {
    final class ErrorTransport: HTTPTransport, @unchecked Sendable {
        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            let resp = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (Data("unauthorized".utf8), resp)
        }
    }
    let provider = ClaudeProvider(apiKey: "bad", transport: ErrorTransport())
    await #expect(throws: AIError.http(status: 401, body: "unauthorized")) {
        _ = try await provider.generateCards(lemmas: ["x"], language: .english, literaryExamples: false)
    }
}
