import { AuthorizeResult, RefreshResult } from 'react-native-app-auth'
import * as Keychain from 'react-native-keychain'

export const setSecureValue = async (key: string, value: string) => {
  await Keychain.setGenericPassword(key, value, {
    service: key
  })
}

export const getSecureValue = async (key: string) => {
  const result = await Keychain.getGenericPassword({ service: key })
  if (result) {
    return result.password
  }
  return false
}

export const removeSecureValue = async (key: string) => {
  await Keychain.resetGenericPassword({ service: key })
}

export const setSecureTokens = async (
  token: AuthorizeResult | RefreshResult
) => {
  const { accessToken, idToken, refreshToken, accessTokenExpirationDate } =
    token
  await setSecureValue('accessToken', accessToken)
  await setSecureValue('idToken', idToken)
  await setSecureValue('refreshToken', refreshToken || '')
  await setSecureValue('accessTokenExpirationDate', accessTokenExpirationDate)
}
