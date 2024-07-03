export enum QuizType {
  SingleChoice = 'singleChoice',
  FillInBlank = 'fillInBlank',
  SplitCombine = 'splitCombine'
}

export interface Quiz {
  _id: string
  answers: string[]
  choices: string[]
  question: string
  translation: string
  type: QuizType
}

export interface Word {
  _id: string
  name: string
  phoneticNotation: string
  syllabification: string[]
  explanation: string
  examples: string[]
  quizzes: Quiz[]
  weightage: number
  isMarked: boolean
}

export interface WordList {
  _id: string
  title: string
  words: Word[]
}

export enum AnswerStatus {
  Unanswered,
  Correct,
  Wrong
}

export interface AnswerInfo {
  answers: string[]
  status: AnswerStatus
}

export type RootStackParamList = {
  Home: undefined
  WordList: undefined
  Detail: { id: string }
  Quiz: { id: string }
  My: undefined
  Login: undefined
  CMS: undefined
  Error: undefined
}
