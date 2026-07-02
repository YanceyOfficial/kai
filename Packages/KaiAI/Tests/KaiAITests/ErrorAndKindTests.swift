import Testing
@testable import KaiAI

@Test("Provider kinds cover claude and openai")
func providerKinds() {
    #expect(Set(LLMProviderKind.allCases) == [.claude, .openai])
    #expect(LLMProviderKind.claude.rawValue == "claude")
}

@Test("AIError is equatable by case and payload")
func errorEquatable() {
    #expect(AIError.http(status: 429, body: "rate") == AIError.http(status: 429, body: "rate"))
    #expect(AIError.http(status: 429, body: "rate") != AIError.http(status: 500, body: "rate"))
    #expect(AIError.missingAPIKey != AIError.emptyResponse)
}
