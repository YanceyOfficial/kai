import Testing
@testable import KaiFSRS

private let s = FSRSScheduler()

@Test("Initial stability equals the per-rating weight w[0...3]")
func initialStabilityUsesWeights() {
    #expect(abs(s.initialStability(.again) - 0.212) < 1e-9)
    #expect(abs(s.initialStability(.hard) - 1.2931) < 1e-9)
    #expect(abs(s.initialStability(.good) - 2.3065) < 1e-9)
    #expect(abs(s.initialStability(.easy) - 8.2956) < 1e-9)
}

@Test("Initial difficulty is clamped to 1...10 and decreases as rating improves")
func initialDifficultyClampedAndOrdered() {
    let again = s.initialDifficulty(.again)
    let easy = s.initialDifficulty(.easy)
    #expect(again >= 1 && again <= 10)
    #expect(easy >= 1 && easy <= 10)
    #expect(again > easy) // harder first grades => higher difficulty
}

@Test("Initial state combines stability and difficulty for the first rating")
func initialStateCombines() {
    let state = s.initialState(.good)
    #expect(abs(state.stability - 2.3065) < 1e-9)
    #expect(abs(state.difficulty - s.initialDifficulty(.good)) < 1e-9)
}
