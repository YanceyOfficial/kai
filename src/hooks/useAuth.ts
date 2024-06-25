import { useState } from 'react'
import { authorize, logout } from 'react-native-app-auth'
import Config from 'react-native-config'
import { OAUTH_REDIRECT_URL } from '../shared/constants'
import { TokenResponse } from '../shared/types'
import { getData, storeData } from '../shared/utils'

export const keycloak = {
  issuer: Config.KEYCLOAK_ISSUER as string,
  clientId: Config.KEYCLOAK_CLIENT_ID as string,
  redirectUrl: OAUTH_REDIRECT_URL,
  scopes: ['openid', 'profile']
}

const useAuth = (onSuccessCallback?: () => void) => {
  const [loading, setLoading] = useState(false)

  const handleLogin = async () => {
    setLoading(true)

    try {
      const authState = await authorize(keycloak)
      storeData('token', authState)
      console.log(authState.refreshToken)

      if (typeof onSuccessCallback === 'function') {
        onSuccessCallback()
      }
    } catch (error) {
      // TODO:
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = async () => {
    try {
      const token = await getData<TokenResponse>('token')
      const result = await logout(keycloak, {
        idToken: token?.idToken || '',
        postLogoutRedirectUrl: Config.KEYCLOAK_LOGOUT_URL || ''
      })
    } catch (error) {
      // TODO:
    } finally {
      setLoading(false)
    }
  }

  return { loading, handleLogin, handleLogout }
}

export default useAuth
