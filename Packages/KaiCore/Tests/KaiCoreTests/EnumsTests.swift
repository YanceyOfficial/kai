import Testing
@testable import KaiCore

@Test("Words apply to all quiz types")
func wordAllowsAllQuizTypes() {
    for type in QuizType.allCases {
        #expect(type.isApplicable(to: .word))
    }
}

@Test("Phrases exclude syllable combining and listening-spelling")
func phraseExcludesSyllableQuizzes() {
    #expect(!QuizType.splitCombine.isApplicable(to: .phrase))
    #expect(!QuizType.listeningSpelling.isApplicable(to: .phrase))
    #expect(QuizType.singleChoice.isApplicable(to: .phrase))
    #expect(QuizType.meaningMatch.isApplicable(to: .phrase))
    #expect(QuizType.fillInBlank.isApplicable(to: .phrase))
    #expect(QuizType.contextCloze.isApplicable(to: .phrase))
}

@Test("Review rating raw values conform to FSRS convention")
func ratingRawValues() {
    #expect(ReviewRating.again.rawValue == 1)
    #expect(ReviewRating.hard.rawValue == 2)
    #expect(ReviewRating.good.rawValue == 3)
    #expect(ReviewRating.easy.rawValue == 4)
}
