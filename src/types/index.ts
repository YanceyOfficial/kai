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
  factor: number
  isMarked: boolean
  isLearned: boolean
  createdAt: string
  updatedAt: string
}

export interface WordList {
  total: number
  page: number
  pageSize: number
  items: Word[]
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

export enum FactorAction {
  Addition,
  Subtraction
}

export interface StatusDto {
  action: FactorAction
  isMarked?: boolean
}

export interface MarkDto {
  isMarked: boolean
}

export type RootStackParamList = {
  Home: undefined
  WordList: undefined
  Detail: { page: number; fromChallenging: boolean }
  Quiz: { page: number }
  My: undefined
  Configuration: undefined
  System: undefined
  Login: undefined
  CMS: undefined
  Error: undefined
}

export interface Pagination {
  page: number
  pageSize: number
}

export interface Statistics {
  items: Chunk[]
  challengingCount: number
}

export interface Chunk {
  total: number
  page: number
  learnedCount: number
}
