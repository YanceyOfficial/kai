import { atom } from 'jotai'
import { AnswerInfo, AnswerStatus, Quiz } from 'src/types'

export const quizzesAtom = atom<Quiz[] | null>(null)

export const quizIdxAtom = atom(0)

export const answerInfoAtom = atom<AnswerInfo>({
  answers: [],
  status: AnswerStatus.Unanswered
})
