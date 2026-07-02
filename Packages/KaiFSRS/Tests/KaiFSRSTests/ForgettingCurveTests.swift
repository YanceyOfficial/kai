import Testing
@testable import KaiFSRS

private let scheduler = FSRSScheduler()

@Test("Retrievability equals 0.9 at t == stability")
func retrievabilityAtStabilityIs90Percent() {
    let r = scheduler.retrievability(elapsedDays: 10, stability: 10)
    #expect(abs(r - 0.9) < 1e-6)
}

@Test("Retrievability is 1.0 at t == 0 and decreases over time")
func retrievabilityMonotonicallyDecreases() {
    #expect(abs(scheduler.retrievability(elapsedDays: 0, stability: 10) - 1.0) < 1e-9)
    let early = scheduler.retrievability(elapsedDays: 5, stability: 10)
    let late = scheduler.retrievability(elapsedDays: 20, stability: 10)
    #expect(early > late)
}

@Test("Next interval equals stability (rounded) at 0.9 desired retention")
func intervalEqualsStabilityAt90() {
    #expect(scheduler.nextInterval(stability: 10) == 10)
    #expect(scheduler.nextInterval(stability: 44) == 44)
}

@Test("Next interval is clamped to at least 1 day and at most maximumInterval")
func intervalClamped() {
    #expect(scheduler.nextInterval(stability: 0.01) == 1)
    let capped = FSRSScheduler(maximumInterval: 30)
    #expect(capped.nextInterval(stability: 100000) == 30)
}
