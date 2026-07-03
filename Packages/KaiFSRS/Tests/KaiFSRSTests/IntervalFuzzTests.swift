import Testing
@testable import KaiFSRS

/// A small deterministic RNG so fuzz output is reproducible in tests.
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

@Test("Intervals below ~2.5 days are not fuzzed")
func smallIntervalsUnchanged() {
    let s = FSRSScheduler()
    var rng = SeededRNG(seed: 1)
    #expect(s.fuzzedInterval(1, using: &rng) == 1)
    #expect(s.fuzzedInterval(2, using: &rng) == 2)
}

@Test("Fuzz stays within the ts-fsrs band")
func fuzzWithinBand() {
    let s = FSRSScheduler()
    var rng = SeededRNG(seed: 99)
    // For interval 100 the band is [93, 107] (delta ≈ 6.975).
    for _ in 0..<200 {
        let f = s.fuzzedInterval(100, using: &rng)
        #expect(f >= 93 && f <= 107)
    }
}

@Test("Fuzz respects the maximum interval")
func fuzzRespectsMaximum() {
    let s = FSRSScheduler(maximumInterval: 100)
    var rng = SeededRNG(seed: 7)
    for _ in 0..<50 {
        #expect(s.fuzzedInterval(100, using: &rng) <= 100)
    }
}
