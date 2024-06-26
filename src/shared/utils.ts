import AsyncStorage from '@react-native-async-storage/async-storage'
import { AuthorizeResult, RefreshResult } from 'react-native-app-auth'
import * as Keychain from 'react-native-keychain'

export const storeData = async <T>(key: string, value: T) => {
  try {
    const jsonValue = JSON.stringify(value)
    await AsyncStorage.setItem(key, jsonValue)
  } catch (e) {
    // saving error
  }
}

export const getData = async <T>(
  key: string
): Promise<Awaited<T> | undefined> => {
  try {
    const jsonValue = await AsyncStorage.getItem(key)
    return jsonValue != null ? JSON.parse(jsonValue) : null
  } catch (e) {
    // error reading value
  }
}

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
