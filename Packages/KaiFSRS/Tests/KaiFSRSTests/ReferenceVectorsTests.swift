import Testing
@testable import KaiFSRS

/// Numeric validation against the canonical ts-fsrs (FSRS-6) reference
/// implementation, using the same 21 default weights, request retention 0.9,
/// fuzzing disabled, and short-term steps disabled.
///
/// Each expected row is one review transition captured from ts-fsrs:
/// the rating, the elapsed days ts-fsrs fed into that transition, and the
/// resulting stability/difficulty and interval (round(stability)). Driving
/// KaiFSRS with the identical (state, rating, elapsedDays) inputs must
/// reproduce the same memory state, which validates every formula end to end.
private let scheduler = FSRSScheduler()

private struct RefStep {
    let rating: FSRSRating
    let elapsed: Double
    let stability: Double
    let difficulty: Double
    let interval: Int
}

/// Relative tolerance comparison, tight for small magnitudes and forgiving for large stabilities.
private func approxEqual(_ got: Double, _ expected: Double) -> Bool {
    abs(got - expected) <= 1e-5 * max(1.0, abs(expected))
}

private func verify(_ steps: [RefStep], _ label: String) {
    var state: FSRSMemoryState? = nil
    for (i, step) in steps.enumerated() {
        let result = scheduler.review(state: state, rating: step.rating, elapsedDays: step.elapsed)
        #expect(approxEqual(result.state.stability, step.stability), "\(label) step \(i): stability \(result.state.stability) != \(step.stability)")
        #expect(approxEqual(result.state.difficulty, step.difficulty), "\(label) step \(i): difficulty \(result.state.difficulty) != \(step.difficulty)")
        #expect(result.intervalDays == step.interval, "\(label) step \(i): interval \(result.intervalDays) != \(step.interval)")
        state = result.state
    }
}

@Test("Matches ts-fsrs reference for five consecutive Good reviews")
func matchesReferenceGoodX5() {
    verify([
        RefStep(rating: .good, elapsed: 0,   stability: 2.3065,       difficulty: 2.11810397, interval: 2),
        RefStep(rating: .good, elapsed: 3,   stability: 13.82690327,  difficulty: 2.11121424, interval: 14),
        RefStep(rating: .good, elapsed: 14,  stability: 56.95670978,  difficulty: 2.1043314,  interval: 57),
        RefStep(rating: .good, elapsed: 57,  stability: 196.23528243, difficulty: 2.09745544, interval: 196),
        RefStep(rating: .good, elapsed: 196, stability: 586.48348981, difficulty: 2.09058635, interval: 586),
    ], "good_x5")
}

@Test("Matches ts-fsrs reference for a mixed rating sequence")
func matchesReferenceMixed() {
    verify([
        RefStep(rating: .good,  elapsed: 0, stability: 2.3065,      difficulty: 2.11810397, interval: 2),
        RefStep(rating: .again, elapsed: 3, stability: 0.63685069,  difficulty: 7.39450274, interval: 1),
        RefStep(rating: .good,  elapsed: 1, stability: 2.44661061,  difficulty: 7.38233661, interval: 2),
        RefStep(rating: .hard,  elapsed: 3, stability: 5.29501485,  difficulty: 8.24750143, interval: 5),
        RefStep(rating: .easy,  elapsed: 5, stability: 15.98554608, difficulty: 7.64712644, interval: 16),
    ], "mixed")
}

@Test("Matches ts-fsrs reference for same-day (short-term) reviews")
func matchesReferenceShortTerm() {
    // A first Good review, then an immediate same-day (elapsed 0) review, exercises
    // the short-term stability path (validated against ts-fsrs with short-term enabled).
    let initial = scheduler.review(state: nil, rating: .good, elapsedDays: 0).state

    // Same-day Good: for G >= 3 the increase factor clamps to 1, so stability is
    // unchanged; difficulty still updates.
    let sameDayGood = scheduler.review(state: initial, rating: .good, elapsedDays: 0).state
    #expect(approxEqual(sameDayGood.stability, 2.3065))
    #expect(approxEqual(sameDayGood.difficulty, 2.11121424))

    // Same-day Again: the short-term formula (not the lapse formula) reduces stability.
    let sameDayAgain = scheduler.review(state: initial, rating: .again, elapsedDays: 0).state
    #expect(approxEqual(sameDayAgain.stability, 0.77508398))
    #expect(approxEqual(sameDayAgain.difficulty, 7.39450274))
}
