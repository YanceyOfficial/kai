import Testing
@testable import KaiFSRS

private let s = FSRSScheduler()

@Test("A new card (nil state) uses the initial state and its interval")
func newCardUsesInitialState() {
    let result = s.review(state: nil, rating: .good, elapsedDays: 0)
    #expect(abs(result.state.stability - s.initialStability(.good)) < 1e-9)
    #expect(result.intervalDays == s.nextInterval(stability: s.initialStability(.good)))
}

@Test("A recalled review (good) increases stability and yields a longer interval")
func recallGrowsIntervalOverTime() {
    let first = s.review(state: nil, rating: .good, elapsedDays: 0)
    let second = s.review(state: first.state, rating: .good, elapsedDays: Double(first.intervalDays))
    #expect(second.state.stability > first.state.stability)
    #expect(second.intervalDays > first.intervalDays)
}

@Test("Again on a reviewed card reduces stability versus a Good on the same card")
func lapseReducesStabilityVersusRecall() {
    let base = s.review(state: nil, rating: .good, elapsedDays: 0)
    let elapsed = Double(base.intervalDays)
    let lapsed = s.review(state: base.state, rating: .again, elapsedDays: elapsed)
    let recalled = s.review(state: base.state, rating: .good, elapsedDays: elapsed)
    #expect(lapsed.state.stability < recalled.state.stability)
}

@Test("Same-day review (elapsed 0) on an existing card uses short-term stability")
func sameDayUsesShortTerm() {
    let base = s.review(state: nil, rating: .good, elapsedDays: 0)
    let sameDay = s.review(state: base.state, rating: .good, elapsedDays: 0)
    #expect(abs(sameDay.state.stability - s.shortTermStability(stability: base.state.stability, rating: .good)) < 1e-9)
}
