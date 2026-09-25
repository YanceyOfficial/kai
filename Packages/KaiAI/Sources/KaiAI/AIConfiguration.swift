import Foundation

/// User-configurable AI settings (provider, key, optional model override).
public struct AIConfiguration: Sendable {
    public var kind: LLMProviderKind
    public var apiKey: String
    /// nil uses the provider's default model.
    public var model: String?
    /// The model's own output ceiling, from its list-models entry (`ModelInfo`); nil
    /// when the provider does not report one, and the provider's default applies.
    public var maxOutputTokens: Int?

    public init(kind: LLMProviderKind, apiKey: String, model: String? = nil, maxOutputTokens: Int? = nil) {
        self.kind = kind
        self.apiKey = apiKey
        self.model = model
        self.maxOutputTokens = maxOutputTokens
    }
}
