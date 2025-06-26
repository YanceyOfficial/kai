import { AnswerInfo, Quiz, QuizType } from '@/shared/types'
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'
import { YOUDAO_VOICE_URL } from './constants'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function youdaoWordAudioUrl(word: string) {
  return `${YOUDAO_VOICE_URL}${word}`
}

export const checkAnswer = (answerInfo: AnswerInfo, quiz: Quiz) => {
  switch (quiz.type) {
    case QuizType.SingleChoice:
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
