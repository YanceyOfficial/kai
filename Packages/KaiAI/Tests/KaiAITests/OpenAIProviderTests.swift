import Foundation
import Testing
import KaiCore
@testable import KaiAI

private final class CapturingTransport2: HTTPTransport, @unchecked Sendable {
    let responseBody: Data
    private(set) var lastRequest: URLRequest?
    init(responseBody: Data) { self.responseBody = responseBody }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (responseBody, resp)
    }
}

private let openAIBody: Data = {
    let inner = #"{"cards":[{"lemma":"obsession","kind":"word","phonetic":"/x/","syllables":["ob"],"explanation":"fixation","partsOfSpeech":["noun"],"examples":[{"sentence":"a","translation":"b"}],"mnemonic":"m","etymology":"e","synonyms":[],"confusables":[],"quizzes":[]}]}"#
    let envelope: [String: Any] = ["choices": [["message": ["role": "assistant", "content": inner]]]]
    return try! JSONSerialization.data(withJSONObject: envelope)
}()

@Test("OpenAIProvider builds a chat-completions json_schema request and decodes cards")
func openAIGenerateCards() async throws {
    let transport = CapturingTransport2(responseBody: openAIBody)
    let provider = OpenAIProvider(apiKey: "sk-oa", model: "gpt-5.5", transport: transport)
    let cards = try await provider.generateCards(lemmas: ["obsession"], language: .english, literaryExamples: true)

    #expect(cards.first?.lemma == "obsession")
    let req = try #require(transport.lastRequest)
    #expect(req.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
    #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer sk-oa")
    let obj = try JSONSerialization.jsonObject(with: try #require(req.httpBody)) as! [String: Any]
    let rf = obj["response_format"] as! [String: Any]
    #expect(rf["type"] as? String == "json_schema")
    let js = rf["json_schema"] as! [String: Any]
    #expect(js["strict"] as? Bool == true)
    #expect(js["schema"] != nil)
}

@Test("OpenAIProvider maps non-2xx to AIError.http")
func openAIHTTPError() async throws {
    final class ErrorTransport: HTTPTransport, @unchecked Sendable {
        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            let resp = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (Data("unauthorized".utf8), resp)
        }
    }
    let provider = OpenAIProvider(apiKey: "bad", transport: ErrorTransport())
    await #expect(throws: AIError.http(status: 401, body: "unauthorized")) {
        _ = try await provider.generateCards(lemmas: ["x"], language: .english, literaryExamples: false)
    }
}

@Test("OpenAIProvider throws emptyResponse for empty choices")
func openAIEmptyChoices() async throws {
    final class StubTransport: HTTPTransport, @unchecked Sendable {
        let responseBody: Data
        init(responseBody: Data) { self.responseBody = responseBody }
        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (responseBody, resp)
        }
    }
    let env = try JSONSerialization.data(withJSONObject: ["choices": []])
    let provider = OpenAIProvider(apiKey: "k", transport: StubTransport(responseBody: env))
    await #expect(throws: AIError.emptyResponse) {
        _ = try await provider.generateCards(lemmas: ["x"], language: .english, literaryExamples: false)
    }
}
