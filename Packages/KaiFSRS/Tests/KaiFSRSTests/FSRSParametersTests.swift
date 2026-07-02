import Testing
@testable import KaiFSRS

@Test("Default FSRS-6 parameters have 21 weights with the documented values")
func defaultParametersShape() {
    let p = FSRSParameters.fsrs6Default
    #expect(p.weights.count == 21)
    #expect(abs(p.weights[0] - 0.212) < 1e-9)
    #expect(abs(p.weights[20] - 0.1542) < 1e-9)
}

@Test("Memory state stores stability and difficulty")
func memoryStateHoldsValues() {
    let s = FSRSMemoryState(stability: 2.5, difficulty: 5.0)
    #expect(s.stability == 2.5)
    #expect(s.difficulty == 5.0)
}
