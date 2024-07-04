import { useState } from 'react'
import { authorize, logout } from 'react-native-app-auth'
import Config from 'react-native-config'
import { OAUTH_REDIRECT_URL } from '../shared/constants'
import { getSecureValue, setSecureTokens } from '../shared/utils'

export const keycloak = {
  issuer: Config.KEYCLOAK_ISSUER as string,
  clientId: Config.KEYCLOAK_CLIENT_ID as string,
  redirectUrl: OAUTH_REDIRECT_URL,
  scopes: ['openid', 'profile', 'offline_access']
}

const useAuth = (onSuccessCallback?: () => void) => {
  const [loading, setLoading] = useState(false)

  const handleLogin = async () => {
    setLoading(true)

    try {
      const tokens = await authorize(keycloak)
      await setSecureTokens(tokens)

      if (typeof onSuccessCallback === 'function') {
        onSuccessCallback()
      }
    } catch (error) {
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = async () => {
    try {
      const idToken = await getSecureValue('idToken')

      if (idToken) {
        await logout(keycloak, {
          idToken,
          postLogoutRedirectUrl: OAUTH_REDIRECT_URL
        })
      }
    } catch (error) {
      // TODO:
    } finally {
      setLoading(false)
    }
  }

  return { loading, handleLogin, handleLogout }
}

export default useAuth
