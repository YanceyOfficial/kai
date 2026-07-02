import Foundation

/// User-configurable AI settings (provider, key, optional model override, example style).
public struct AIConfiguration: Sendable {
    public var kind: LLMProviderKind
    public var apiKey: String
    /// nil uses the provider's default model.
    public var model: String?
    public var literaryExamples: Bool

    public init(kind: LLMProviderKind, apiKey: String, model: String? = nil, literaryExamples: Bool = false) {
        self.kind = kind
        self.apiKey = apiKey
        self.model = model
        self.literaryExamples = literaryExamples
    }
}
