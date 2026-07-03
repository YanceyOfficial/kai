import Foundation

/// A user-authored note attached to a vocabulary entry — like a personal comment for a
/// modern or contextual sense the AI-generated (textbook) content would not include.
/// Embedded as a Codable value type in entries; never produced by the AI layer.
public struct Annotation: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var text: String
    public var createdAt: Date

    public init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}
