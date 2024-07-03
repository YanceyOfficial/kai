import { AnswerInfo, Quiz, QuizType } from 'shared/types'

export const checkAnswer = (answerInfo: AnswerInfo, quiz: Quiz) => {
  switch (quiz.type) {
    case QuizType.SingleChoice:
      console.log(answerInfo.answers.join(''))
      return answerInfo.answers.every((answer) =>
        quiz?.answers.includes(answer)
      )
    case QuizType.SplitCombine:
      return (
        answerInfo.answers.join('') ===
        quiz.answers.join('').replace(/\s+/g, '')
      )
    default:
      return false
  }
}
