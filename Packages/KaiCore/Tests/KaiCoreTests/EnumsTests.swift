import Testing
@testable import KaiCore

@Test("单词适用全部题型")
func wordAllowsAllQuizTypes() {
    for type in QuizType.allCases {
        #expect(type.isApplicable(to: .word))
    }
}

@Test("短语不出音节拼词与听音拼写")
func phraseExcludesSyllableQuizzes() {
    #expect(!QuizType.splitCombine.isApplicable(to: .phrase))
    #expect(!QuizType.listeningSpelling.isApplicable(to: .phrase))
    #expect(QuizType.singleChoice.isApplicable(to: .phrase))
    #expect(QuizType.meaningMatch.isApplicable(to: .phrase))
    #expect(QuizType.fillInBlank.isApplicable(to: .phrase))
    #expect(QuizType.contextCloze.isApplicable(to: .phrase))
}

@Test("评级 raw 值符合 FSRS 约定")
func ratingRawValues() {
    #expect(ReviewRating.again.rawValue == 1)
    #expect(ReviewRating.easy.rawValue == 4)
}
