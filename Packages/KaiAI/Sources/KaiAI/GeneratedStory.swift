import Foundation

/// A short study passage produced by the model: an English `story` that uses the
/// requested words, plus a Chinese `translation` of the whole passage.
public struct GeneratedStory: Codable, Equatable, Sendable {
    public let story: String
    public let translation: String
}

/// The provider-agnostic JSON schema for story generation, matching `GeneratedStory`.
public enum StorySchema {
    public static var story: JSONSchema {
        .object(["story": .string, "translation": .string], required: ["story", "translation"])
    }
}
