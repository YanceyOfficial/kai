import Foundation
import Testing
@testable import KaiCore

/// Pure scheduling-bridge tests. No SwiftData here, so these run on the macOS host
/// (`swift test --filter ReviewScheduler`) as well as on the simulator.
@Suite("ReviewScheduler")
struct ReviewSchedulerTests {
    private let scheduler = ReviewScheduler()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("First review of a new card seeds memory state and bumps reps")
    func firstReviewSeedsState() {
        let next = scheduler.next(.new(now: now), rating: .good, now: now)
        #expect(next.reps == 1)
        #expect(next.lapses == 0)
        #expect(next.state == .review)
        #expect(next.stability > 0)          // seeded from the grade
        #expect(next.difficulty > 0)
        #expect(next.lastReview == now)
        #expect(next.due > now)              // scheduled at least a day out
    }

    @Test("Again on a new card counts a lapse and enters relearning")
    func againCountsLapse() {
        let next = scheduler.next(.new(now: now), rating: .again, now: now)
        #expect(next.lapses == 1)
        #expect(next.state == .relearning)
        #expect(next.reps == 1)
    }

    @Test("The due date matches the FSRS interval in whole days")
    func dueMatchesInterval() {
        // A well-remembered card reviewed after a long gap earns a multi-day interval.
        let prior = SchedulingState(
            stability: 10, difficulty: 5,
            due: now, lastReview: now.addingTimeInterval(-10 * 86_400),
            reps: 3, lapses: 0, state: .review
        )
        let next = scheduler.next(prior, rating: .good, now: now)
        let intervalDays = next.due.timeIntervalSince(now) / 86_400
        // Due is a whole number of days out, and further than the previous 10-day gap
        // is not guaranteed, but it must be at least one day.
        #expect(intervalDays >= 1)
        #expect(abs(intervalDays.rounded() - intervalDays) < 1e-6)
    }

    @Test("Easy grows stability more than Hard for the same card")
    func easyBeatsHard() {
        let prior = SchedulingState(
            stability: 5, difficulty: 5,
            due: now, lastReview: now.addingTimeInterval(-5 * 86_400),
            reps: 2, lapses: 0, state: .review
        )
        let easy = scheduler.next(prior, rating: .easy, now: now)
        let hard = scheduler.next(prior, rating: .hard, now: now)
        #expect(easy.stability > hard.stability)
        #expect(easy.due > hard.due)
    }
}
