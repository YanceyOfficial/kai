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
    /// Whether to apply interval fuzz. Disabled in tests for deterministic assertions.
    private let fuzz: Bool

    public init(fsrs: FSRSScheduler = FSRSScheduler(), fuzz: Bool = true) {
        self.fsrs = fsrs
        self.fuzz = fuzz
    }

    /// Convenience: build with a target `requestRetention` (the recall probability at which
    /// a word becomes due). Higher → shorter intervals / more reviews.
    public init(requestRetention: Double, fuzz: Bool = true) {
        self.init(fsrs: FSRSScheduler(requestRetention: requestRetention), fuzz: fuzz)
    }

    /// Seconds per day, used to turn an FSRS interval (whole days) into a due date.
    private static let secondsPerDay: Double = 86_400

    /// Sub-day learning steps. A lapse (`Again`) always drops to the short step so the
    /// word can be re-drilled within the session; `Hard` on a not-yet-graduated card
    /// takes the longer step. `Good`/`Easy`, and any rating on a mature `.review` card,
    /// graduate to the FSRS day interval.
    private static let againStep: TimeInterval = 60        // 1 minute
    private static let hardLearningStep: TimeInterval = 600 // 10 minutes

    /// The scheduling state after grading `state` with `rating` at `now`.
    ///
    /// A card still in the `.new` state is seeded from the grade (no prior memory
    /// state); otherwise FSRS evolves the existing stability/difficulty using the
    /// time elapsed since the last review. FSRS still governs the stored stability and
    /// difficulty; the learning steps only shorten the *due date* for cards that
    /// haven't graduated yet, so weak words resurface quickly.
    public func next(_ state: SchedulingState, rating: ReviewRating, now: Date = .now) -> SchedulingState {
        let grade = FSRSRating(rawValue: rating.rawValue) ?? .good

        // A brand-new card has no memory state yet; FSRS seeds it from the grade.
        let priorState: FSRSMemoryState? = state.state == .new
            ? nil
            : FSRSMemoryState(stability: state.stability, difficulty: state.difficulty)

        // Whole days since the last review — floored, so any same-day review (learning
        // re-drills, a chained quiz, several reviews in a day) counts as elapsed 0 and
        // takes FSRS's short-term stability path, matching ts-fsrs.
        let elapsedDays: Double = state.lastReview.map { last in
            (max(0, now.timeIntervalSince(last)) / Self.secondsPerDay).rounded(.down)
        } ?? 0

        let result = fsrs.review(state: priorState, rating: grade, elapsedDays: elapsedDays)

        // Cards not yet graduated take short learning steps; everyone else uses the
        // FSRS day interval (with fuzz so cards don't clump on one day).
        let inLearningPhase = state.state == .new || state.state == .learning || state.state == .relearning
        let interval: TimeInterval
        let nextState: LearningState
        switch rating {
        case .again:
            interval = Self.againStep
            nextState = .relearning
        case .hard where inLearningPhase:
            interval = Self.hardLearningStep
            nextState = .learning
        default:
            interval = Double(fuzzedDays(result.intervalDays)) * Self.secondsPerDay
            nextState = .review
        }

        return SchedulingState(
            stability: result.state.stability,
            difficulty: result.state.difficulty,
            due: now.addingTimeInterval(interval),
            lastReview: now,
            reps: state.reps + 1,
            // A lapse only counts when a *graduated* word is failed; re-drills of a
            // still-learning/relearning word don't each add a lapse.
            lapses: state.lapses + (rating == .again && state.state == .review ? 1 : 0),
            state: nextState
        )
    }

    /// The day interval with fuzz applied (when enabled).
    private func fuzzedDays(_ days: Int) -> Int {
        guard fuzz else { return days }
        var rng = SystemRandomNumberGenerator()
        return fsrs.fuzzedInterval(days, using: &rng)
    }
}
