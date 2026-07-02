import Foundation

/// User-configurable AI settings (provider, key, optional model override).
public struct AIConfiguration: Sendable {
    public var kind: LLMProviderKind
    public var apiKey: String
    /// nil uses the provider's default model.
    public var model: String?

    public init(kind: LLMProviderKind, apiKey: String, model: String? = nil) {
        self.kind = kind
        self.apiKey = apiKey
        self.model = model
    }
}
