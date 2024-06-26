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
  Home: undefined
  WordList: undefined
  Detail: { id: string }
  My: undefined
  Login: undefined
}
