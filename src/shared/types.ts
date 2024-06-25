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
  Detail: { id: string }
}

export interface TokenResponse {
  accessToken: string
  accessTokenExpirationDate: string
  authorizeAdditionalParameters?: { [name: string]: string }
  tokenAdditionalParameters?: { [name: string]: string }
  idToken: string
  refreshToken: string | null
  tokenType: string
  scopes: string[]
  authorizationCode: string
  codeVerifier?: string
  additionalParameters?: { [name: string]: string }
}
