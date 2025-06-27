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

function decodeJwtPayload(token: string): { exp: number } {
  const base64 = token.split('.')[1]
  const json = atob(base64.replace(/-/g, '+').replace(/_/g, '/'))
  return JSON.parse(json)
}

export function isTokenExpiringSoon(accessToken: string): boolean {
  try {
    const decoded = decodeJwtPayload(accessToken)
    if (decoded.exp === undefined) {
      throw new Error('')
    }
    const now = Math.floor(Date.now() / 1000)
    return now > decoded.exp - 60 * 1000
  } catch {
    return true
  }
}
