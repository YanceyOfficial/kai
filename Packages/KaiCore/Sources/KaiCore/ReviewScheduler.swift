import Foundation
import KaiFSRS

/// Bridges Kai's persisted `SchedulingState` with the pure FSRS-6 algorithm in
/// `KaiFSRS`. Given a card's current state and a rating, it produces the next
/// scheduling state — new stability/difficulty, next due date, and bumped counters.
///
/// This is the single place where a review turns into a schedule. It is pure (no
/// persistence, no clock of its own) so it stays deterministic and testable; the
/// caller passes `now` and persists the returned state.
public struct ReviewScheduler: Sendable {
    private let fsrs: FSRSScheduler

    public init(fsrs: FSRSScheduler = FSRSScheduler()) {
        self.fsrs = fsrs
    }

    /// Seconds per day, used to turn an FSRS interval (whole days) into a due date.
    private static let secondsPerDay: Double = 86_400

    /// The scheduling state after grading `state` with `rating` at `now`.
    ///
    /// A card still in the `.new` state is seeded from the grade (no prior memory
    /// state); otherwise FSRS evolves the existing stability/difficulty using the
    /// time elapsed since the last review.
    public func next(_ state: SchedulingState, rating: ReviewRating, now: Date = .now) -> SchedulingState {
        let grade = FSRSRating(rawValue: rating.rawValue) ?? .good

        // A brand-new card has no memory state yet; FSRS seeds it from the grade.
        let priorState: FSRSMemoryState? = state.state == .new
            ? nil
            : FSRSMemoryState(stability: state.stability, difficulty: state.difficulty)

        // Days since the last review (0 for a new or same-instant review).
        let elapsedDays: Double = state.lastReview.map { last in
            max(0, now.timeIntervalSince(last) / Self.secondsPerDay)
        } ?? 0

        let result = fsrs.review(state: priorState, rating: grade, elapsedDays: elapsedDays)

        return SchedulingState(
            stability: result.state.stability,
            difficulty: result.state.difficulty,
            due: now.addingTimeInterval(Double(result.intervalDays) * Self.secondsPerDay),
            lastReview: now,
            reps: state.reps + 1,
            lapses: state.lapses + (rating == .again ? 1 : 0),
            // We model no sub-day learning steps yet: a lapse relearns, anything else
            // graduates to review. The state is informational (scheduling is driven
            // by stability), so this simplification is safe.
            state: rating == .again ? .relearning : .review
        )
    }
}
