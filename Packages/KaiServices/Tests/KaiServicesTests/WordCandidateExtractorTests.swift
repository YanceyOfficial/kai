import Testing
@testable import KaiServices

@Test("Extractor strips punctuation, drops non-alpha and short tokens, dedupes case-insensitively")
func candidateFiltering() {
    let extractor = WordCandidateExtractor(minLength: 2)
    let lines = ["The eccentric, obsessive genius.", "genius 42 a", "Eccentric!"]
    let out = extractor.candidates(from: lines)
    // "The" -> "the"; "eccentric"; "obsessive"; "genius"; then dupes/short/numeric dropped.
    #expect(out == ["the", "eccentric", "obsessive", "genius"])
}

@Test("Empty and whitespace-only input yields no candidates")
func emptyInput() {
    let extractor = WordCandidateExtractor()
    #expect(extractor.candidates(from: ["", "   ", "!!!"]).isEmpty)
}
