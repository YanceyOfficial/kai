import Foundation

/// Builds the configured provider with retry-wrapped transport. Single entry point for callers.
public enum ProviderFactory {
    /// Default model per provider when the configuration doesn't override it.
    static func defaultModel(for kind: LLMProviderKind) -> String {
        switch kind {
        case .claude: return "claude-opus-4-8"
        case .openai: return "gpt-5.5"
        }
    }

    public static func make(
        _ config: AIConfiguration,
        transport: HTTPTransport = URLSessionTransport(),
        retry: RetryPolicy = .default
    ) -> LLMProvider {
        let retrying = RetryingTransport(wrapping: transport, policy: retry)
        let model = config.model ?? defaultModel(for: config.kind)
        switch config.kind {
        case .claude:
            return ClaudeProvider(apiKey: config.apiKey, model: model, transport: retrying)
        case .openai:
            return OpenAIProvider(apiKey: config.apiKey, model: model, transport: retrying)
        }
    }
}
