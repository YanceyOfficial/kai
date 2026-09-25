import Foundation

/// User-configurable AI settings: provider, key, and the model picked from the
/// provider's live list (`ModelListing`) with its output ceiling. Nothing here has a
/// built-in default: the model and its limits are whatever the provider says.
public struct AIConfiguration: Sendable {
    public var kind: LLMProviderKind
    public var apiKey: String
    /// A model id from the provider's list.
    public var model: String
    /// The model's own output ceiling, from its list-models entry (`ModelInfo`). Claude
    /// requires one per request; OpenAI's list reports none, and the request then leaves
    /// the limit to the model.
    public var maxOutputTokens: Int?

    public init(kind: LLMProviderKind, apiKey: String, model: String, maxOutputTokens: Int? = nil) {
        self.kind = kind
        self.apiKey = apiKey
        self.model = model
        self.maxOutputTokens = maxOutputTokens
    }
}
