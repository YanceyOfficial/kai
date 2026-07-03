import Foundation
import Testing
import KaiCore
@testable import KaiAI

private final class StubTransport: HTTPTransport, @unchecked Sendable {
    let responseBody: Data
    private(set) var lastRequest: URLRequest?
    init(responseBody: Data) { self.responseBody = responseBody }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (responseBody, resp)
    }
}

@Test("GeneratedStory decodes from the provider JSON contract")
func decodeStory() throws {
    let json = #"{"story":"He is eccentric.","translation":"他很古怪。"}"#.data(using: .utf8)!
    let story = try JSONDecoder().decode(GeneratedStory.self, from: json)
    #expect(story.story == "He is eccentric.")
    #expect(story.translation == "他很古怪。")
}

@Test("Story prompt names the words and asks for a Chinese translation")
func storyPrompt() {
    let p = PromptBuilder(language: .english, literaryExamples: false)
    #expect(p.storySystemPrompt().contains("English"))
    #expect(p.storySystemPrompt().lowercased().contains("chinese"))
    let user = p.storyUserPrompt(words: ["eccentric", "obsession"])
    #expect(user.contains("eccentric"))
    #expect(user.contains("obsession"))
}

@Test("ClaudeProvider generateStory decodes the passage and translation")
func claudeStory() async throws {
    let inner = #"{"story":"A short tale.","translation":"一个短故事。"}"#
    let envelope: [String: Any] = ["content": [["type": "text", "text": inner]]]
    let body = try JSONSerialization.data(withJSONObject: envelope)
    let provider = ClaudeProvider(apiKey: "sk", transport: StubTransport(responseBody: body))

    let story = try await provider.generateStory(words: ["tale"], language: .english)
    #expect(story.story == "A short tale.")
    #expect(story.translation == "一个短故事。")
}

@Test("OpenAIProvider generateStory decodes the passage and translation")
func openAIStory() async throws {
    let inner = #"{"story":"A short tale.","translation":"一个短故事。"}"#
    let envelope: [String: Any] = ["choices": [["message": ["content": inner]]]]
    let body = try JSONSerialization.data(withJSONObject: envelope)
    let provider = OpenAIProvider(apiKey: "sk", transport: StubTransport(responseBody: body))

    let story = try await provider.generateStory(words: ["tale"], language: .english)
    #expect(story.story == "A short tale.")
}

@Test("generateStory throws missingAPIKey for empty key")
func storyMissingKey() async throws {
    final class Never: HTTPTransport, @unchecked Sendable {
        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) { fatalError() }
    }
    let provider = ClaudeProvider(apiKey: "", transport: Never())
    await #expect(throws: AIError.missingAPIKey) {
        _ = try await provider.generateStory(words: ["x"], language: .english)
    }
}
