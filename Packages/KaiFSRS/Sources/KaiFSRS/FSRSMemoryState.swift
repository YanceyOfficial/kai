import Foundation

/// The FSRS memory state of a card: stability (days) and difficulty (1...10).
public struct FSRSMemoryState: Equatable, Sendable {
    /// Memory stability in days — the time for retrievability to fall to 90%.
    public var stability: Double
    /// Item difficulty on a 1...10 scale.
    public var difficulty: Double

    public init(stability: Double, difficulty: Double) {
        self.stability = stability
        self.difficulty = difficulty
    }
}
