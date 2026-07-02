import Foundation

/// Which LLM backend to use. Selected in settings; both share one request/response abstraction.
public enum LLMProviderKind: String, Codable, CaseIterable, Sendable {
    case claude
    case openai
}
