import Foundation

/// The minimal per-item state the forgetting scheduler needs. The app maps
/// KaiCore entries to this DTO so KaiServices stays free of SwiftData.
public struct ReviewableItem: Equatable, Sendable {
    public let id: UUID
    public let stability: Double
    public let lastReview: Date?
    public init(id: UUID, stability: Double, lastReview: Date?) {
        self.id = id
        self.stability = stability
        self.lastReview = lastReview
    }
}

/// A scheduled forgetting reminder for one item.
public struct ForgettingReminder: Equatable, Sendable {
    public let id: UUID
    public let fireDate: Date
    public init(id: UUID, fireDate: Date) {
        self.id = id
        self.fireDate = fireDate
    }
}
