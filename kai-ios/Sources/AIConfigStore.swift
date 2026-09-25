import Foundation
import KaiAI
import KaiServices

/// Resolves the AI configuration from user settings: the provider kind, the chosen
/// model and the provider's last-fetched model list (`ModelListing`) live in
/// `UserDefaults`, while the API key is kept in the Keychain. Returns a ready
/// `AIConfiguration` only when a key is present.
enum AIConfigStore {
    static let secretStore: SecretStore = KeychainSecretStore(service: "dev.tuist.kai-ios.ai")

    private static func keychainKey(_ kind: LLMProviderKind) -> String { "aiKey.\(kind.rawValue)" }
    private static func modelKey(_ kind: LLMProviderKind) -> String { "aiModel.\(kind.rawValue)" }
    private static func modelsKey(_ kind: LLMProviderKind) -> String { "aiModels.\(kind.rawValue)" }

    static func currentKind() -> LLMProviderKind {
        LLMProviderKind(rawValue: UserDefaults.standard.string(forKey: "aiProvider") ?? "") ?? .claude
    }

    static func apiKey(for kind: LLMProviderKind) -> String {
        ((try? secretStore.string(for: keychainKey(kind))) ?? nil) ?? ""
    }

    static func setApiKey(_ key: String, for kind: LLMProviderKind) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            try? secretStore.removeValue(for: keychainKey(kind))
        } else {
            try? secretStore.set(trimmed, for: keychainKey(kind))
        }
    }

    static func model(for kind: LLMProviderKind) -> String {
        UserDefaults.standard.string(forKey: modelKey(kind)) ?? ""
    }

    static func setModel(_ model: String, for kind: LLMProviderKind) {
        UserDefaults.standard.set(model.trimmingCharacters(in: .whitespaces), forKey: modelKey(kind))
    }

    /// The models the provider listed the last time the key was checked (empty if never).
    static func cachedModels(for kind: LLMProviderKind) -> [ModelInfo] {
        guard let data = UserDefaults.standard.data(forKey: modelsKey(kind)) else { return [] }
        return (try? JSONDecoder().decode([ModelInfo].self, from: data)) ?? []
    }

    static func setCachedModels(_ models: [ModelInfo], for kind: LLMProviderKind) {
        UserDefaults.standard.set(try? JSONEncoder().encode(models), forKey: modelsKey(kind))
    }

    /// The current configuration, or `nil` if no API key has been entered. Carries the
    /// chosen model's own output ceiling when its list entry reported one.
    static func configuration() -> AIConfiguration? {
        let kind = currentKind()
        let key = apiKey(for: kind)
        guard !key.isEmpty else { return nil }
        let model = model(for: kind)
        let limit = cachedModels(for: kind).first { $0.id == model }?.maxOutputTokens
        return AIConfiguration(kind: kind, apiKey: key, model: model.isEmpty ? nil : model, maxOutputTokens: limit)
    }
}
