export interface Word {
  explanation: string
  phoneticNotation: string
  word: string
  examples: string[]
  _id: string
  score: number
}

export interface WordList {
  _id: string
  title: string
  words: Word[]
}

export type RootStackParamList = {
  Login: undefined
  Home: undefined
  My: undefined
  Detail: { id: string }
}
