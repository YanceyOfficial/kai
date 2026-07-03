import Foundation
import KaiAI

/// A curated list of current models per provider, for the settings model picker.
/// Verified against the providers' docs (2026-07): Anthropic ships Opus 4.8 / Sonnet 5
/// / Haiku 4.5 / Fable 5; OpenAI ships GPT-5.5 / 5.5-pro / 5.2 / 5.
enum AIModelCatalog {
    static func models(for kind: LLMProviderKind) -> [String] {
        switch kind {
        case .claude:
            return ["claude-opus-4-8", "claude-sonnet-5", "claude-haiku-4-5", "claude-fable-5"]
        case .openai:
            return ["gpt-5.5", "gpt-5.5-pro", "gpt-5.2", "gpt-5"]
        }
    }

    static func defaultModel(for kind: LLMProviderKind) -> String {
        models(for: kind).first!
    }

    /// Returns `stored` if it is a known model for `kind`, otherwise the default.
    static func resolved(_ stored: String, for kind: LLMProviderKind) -> String {
        models(for: kind).contains(stored) ? stored : defaultModel(for: kind)
    }
}
