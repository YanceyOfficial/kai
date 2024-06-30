export enum QuizType {
  SingleChoice = 'singleChoice',
  FillInBlank = 'fillInBlank'
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

export type RootStackParamList = {
  Home: undefined
  WordList: undefined
  Detail: { id: string }
  Quiz: undefined
  My: undefined
  Login: undefined
}
