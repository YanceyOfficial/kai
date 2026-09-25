import Foundation

/// Builds the configured provider with retry-wrapped transport. Single entry point for callers.
public enum ProviderFactory {
    public static func make(
        _ config: AIConfiguration,
        transport: HTTPTransport = URLSessionTransport(),
        retry: RetryPolicy = .default
    ) -> LLMProvider {
        let retrying = RetryingTransport(wrapping: transport, policy: retry)
        switch config.kind {
        case .claude:
            return ClaudeProvider(apiKey: config.apiKey, model: config.model, transport: retrying, maxTokens: config.maxOutputTokens)
        case .openai:
            return OpenAIProvider(apiKey: config.apiKey, model: config.model, transport: retrying, maxTokens: config.maxOutputTokens)
        }
    }
}
