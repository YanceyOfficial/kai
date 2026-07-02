import Testing
@testable import KaiFSRS

private let s = FSRSScheduler()

@Test("Successful recall increases stability, and Easy beats Good beats Hard")
func recallIncreasesStabilityOrdered() {
    let d = 5.0, stab = 10.0, r = 0.9
    let hard = s.stabilityAfterRecall(difficulty: d, stability: stab, retrievability: r, rating: .hard)
    let good = s.stabilityAfterRecall(difficulty: d, stability: stab, retrievability: r, rating: .good)
    let easy = s.stabilityAfterRecall(difficulty: d, stability: stab, retrievability: r, rating: .easy)
    #expect(hard > stab)
    #expect(hard < good)
    #expect(good < easy)
}

@Test("Lower retrievability on recall yields a larger stability increase")
func recallRewardsHarderRetrieval() {
    let highR = s.stabilityAfterRecall(difficulty: 5, stability: 10, retrievability: 0.95, rating: .good)
    let lowR = s.stabilityAfterRecall(difficulty: 5, stability: 10, retrievability: 0.7, rating: .good)
    #expect(lowR > highR)
}

@Test("Post-lapse stability is positive and does not exceed the pre-lapse stability")
func lapseStabilityBounded() {
    let stab = 20.0
    let sf = s.stabilityAfterLapse(difficulty: 5, stability: stab, retrievability: 0.8)
    #expect(sf > 0)
    #expect(sf <= stab)
}

@Test("Same-day (short-term) Good/Easy do not reduce stability")
func shortTermGoodEasyNonDecreasing() {
    let stab = 5.0
    #expect(s.shortTermStability(stability: stab, rating: .good) >= stab)
    #expect(s.shortTermStability(stability: stab, rating: .easy) >= stab)
}
