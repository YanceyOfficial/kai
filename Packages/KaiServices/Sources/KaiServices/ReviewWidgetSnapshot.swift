import Foundation

/// The App Group shared between the app and its widget.
public let kaiAppGroupID = "group.dev.tuist.kai-ios"

/// A tiny snapshot the app publishes for the home-screen widget (which can't read the
/// app's SwiftData store directly).
public struct ReviewWidgetSnapshot: Codable, Sendable, Equatable {
    public var dueCount: Int
    public var totalWords: Int
    public var updatedAt: Date

    public init(dueCount: Int, totalWords: Int, updatedAt: Date = .now) {
        self.dueCount = dueCount
        self.totalWords = totalWords
        self.updatedAt = updatedAt
    }
}

/// Reads/writes the widget snapshot in the shared App Group container.
public struct WidgetSnapshotStore {
    private let defaults: UserDefaults?
    private let key = "reviewWidgetSnapshot"

    /// Production: the shared App Group suite.
    public init(suiteName: String = kaiAppGroupID) {
        self.defaults = UserDefaults(suiteName: suiteName)
    }

    /// Test seam: an explicit defaults instance.
    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func write(_ snapshot: ReviewWidgetSnapshot) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    public func read() -> ReviewWidgetSnapshot? {
        guard let defaults, let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ReviewWidgetSnapshot.self, from: data)
    }
}
