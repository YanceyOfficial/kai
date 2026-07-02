import Testing
@testable import KaiFSRS

private let s = FSRSScheduler()

@Test("Again increases difficulty, Easy decreases it, Good changes it little")
func difficultyDirection() {
    let d = 5.0
    #expect(s.nextDifficulty(d, rating: .again) > d)
    #expect(s.nextDifficulty(d, rating: .easy) < d)
    let good = s.nextDifficulty(d, rating: .good)
    #expect(abs(good - d) < 0.6) // Good barely moves difficulty
}

@Test("Difficulty stays within 1...10 even under repeated Again")
func difficultyClampedUnderPressure() {
    var d = 5.0
    for _ in 0..<50 { d = s.nextDifficulty(d, rating: .again) }
    #expect(d <= 10.0 && d >= 1.0)
    var e = 5.0
    for _ in 0..<50 { e = s.nextDifficulty(e, rating: .easy) }
    #expect(e >= 1.0 && e <= 10.0)
}
