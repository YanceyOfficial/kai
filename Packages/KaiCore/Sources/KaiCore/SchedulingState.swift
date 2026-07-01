import Foundation

/// Entry's FSRS scheduling state. Embedded as a Codable value type in entries.
/// Specific evolution of stability/difficulty is handled by KaiFSRS package (future plan).
public struct SchedulingState: Codable, Hashable, Sendable {
    /// Memory stability S (days). New entries are 0.
    public var stability: Double
    /// Memory difficulty D (FSRS internal measure, ~1...10). New entries are 0 (pending initialization on first review).
    public var difficulty: Double
    /// Next due date/time.
    public var due: Date
    /// Last review date/time.
    public var lastReview: Date?
    /// Total review count.
    public var reps: Int
    /// Total lapse count.
    public var lapses: Int
    /// Learning stage.
    public var state: LearningState

    public init(
        stability: Double,
        difficulty: Double,
        due: Date,
        lastReview: Date?,
        reps: Int,
        lapses: Int,
        state: LearningState
    ) {
        self.stability = stability
        self.difficulty = difficulty
        self.due = due
        self.lastReview = lastReview
        self.reps = reps
        self.lapses = lapses
        self.state = state
    }

    /// Initial state for new entries: due immediately (can start learning), no stability/difficulty yet.
    public static func new(now: Date = .now) -> SchedulingState {
        SchedulingState(
            stability: 0,
            difficulty: 0,
            due: now,
            lastReview: nil,
            reps: 0,
            lapses: 0,
            state: .new
        )
    }
}
