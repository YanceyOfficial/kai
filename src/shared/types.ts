export interface TokenAdditionalParameters {
  refresh_expires_in: number
  session_state: string
  'not-before-policy': number
}

export interface AuthorizeAdditionalParameters {
  session_state: string
  iss: string
}

export interface TokenResponse {
  refreshToken: string
  scopes: string[]
  accessToken: string
  idToken: string
  tokenAdditionalParameters: TokenAdditionalParameters
  tokenType: string
  authorizeAdditionalParameters: AuthorizeAdditionalParameters
  accessTokenExpirationDate: string
}

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
