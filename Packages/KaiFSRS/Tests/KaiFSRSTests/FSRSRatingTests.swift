import Testing
@testable import KaiFSRS

@Test("FSRS ratings map to the canonical 1...4 grades")
func ratingRawValues() {
    #expect(FSRSRating.again.rawValue == 1)
    #expect(FSRSRating.hard.rawValue == 2)
    #expect(FSRSRating.good.rawValue == 3)
    #expect(FSRSRating.easy.rawValue == 4)
    #expect(FSRSRating.allCases.count == 4)
}
