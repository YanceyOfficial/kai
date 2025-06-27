import { OAUTH_REDIRECT_URL } from '@/shared/constants'
import type { UserInfo } from '@/shared/types'
import { isTokenExpiringSoon } from '@/shared/utils'
import * as AuthSession from 'expo-auth-session'
import * as SecureStore from 'expo-secure-store'
import {
  createContext,
  ReactNode,
  useCallback,
  useContext,
  useEffect,
  useState
} from 'react'

export const authConfig = {
  clientId: process.env.EXPO_PUBLIC_KEYCLOAK_CLIENT_ID!,
  redirectUri: AuthSession.makeRedirectUri({ scheme: OAUTH_REDIRECT_URL })
}

const AuthContext = createContext<{
  userInfo: UserInfo | null
  loading: boolean
  signIn: (
    options?: AuthSession.AuthRequestPromptOptions
  ) => Promise<AuthSession.AuthSessionResult>
  signOut: () => Promise<void>
  reloadUserInfo: () => Promise<void>
} | null>(null)

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [loading, setLoading] = useState(true)
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null)

  const discovery = AuthSession.useAutoDiscovery(
    process.env.EXPO_PUBLIC_KEYCLOAK_ISSUER!
  )

  const [request, response, promptAsync] = AuthSession.useAuthRequest(
    {
      ...authConfig,
      responseType: AuthSession.ResponseType.Code,
      prompt: AuthSession.Prompt.Login,
      scopes: ['openid', 'profile', 'email', 'offline_access']
    },
    discovery
  )

  const signOut = useCallback(async () => {
    await SecureStore.deleteItemAsync('access_token')
    await SecureStore.deleteItemAsync('refresh_token')
    setUserInfo(null)
  }, [])

  const updateRefreshToken = useCallback(async () => {
    const refreshToken = await SecureStore.getItemAsync('refresh_token')
    if (!refreshToken || !discovery) return

    try {
      const result = await AuthSession.refreshAsync(
        {
          clientId: authConfig.clientId,
          refreshToken
        },
        discovery
      )

      await SecureStore.setItemAsync('access_token', result.accessToken)
      if (result.refreshToken) {
        await SecureStore.setItemAsync('refresh_token', result.refreshToken)
      }
    } catch (err) {
      console.warn('Refresh token failed:', err)
      await signOut()
    }
  }, [discovery, signOut])

  const loadUserInfo = useCallback(async () => {
    const accessToken = await SecureStore.getItemAsync('access_token')
    if (!accessToken || !discovery) {
      setLoading(false)
      return
    }

    try {
      const info = (await AuthSession.fetchUserInfoAsync(
        { accessToken },
        discovery
      )) as UserInfo

      setUserInfo(info)
    } catch (err) {
      console.warn('Fetching user info failed:', err)
      setUserInfo(null)
    } finally {
      setLoading(false)
    }
  }, [discovery])

  useEffect(() => {
    const handleAuthResult = async () => {
      if (!discovery || response?.type !== 'success') return

      try {
        const tokenResult = await AuthSession.exchangeCodeAsync(
          {
            ...authConfig,
            code: response.params.code,
            extraParams: {
              code_verifier: request?.codeVerifier ?? ''
            }
          },
          discovery
        )

        await SecureStore.setItemAsync('access_token', tokenResult.accessToken)
        if (tokenResult.refreshToken) {
          await SecureStore.setItemAsync(
            'refresh_token',
            tokenResult.refreshToken
          )
        }

        await loadUserInfo()
      } catch (err) {
        console.error('Exchange code failed:', err)
      }
    }

    handleAuthResult()
  }, [response, request?.codeVerifier, discovery, loadUserInfo])

  useEffect(() => {
    const bootstrap = async () => {
      const accessToken = await SecureStore.getItemAsync('access_token')
      if (!accessToken ) return

      if (isTokenExpiringSoon(accessToken)) {
        await updateRefreshToken()
        await loadUserInfo()
      }
    }

    bootstrap()
  }, [loadUserInfo, updateRefreshToken])

  return (
    <AuthContext.Provider
      value={{
        userInfo,
        loading,
        signIn: promptAsync,
        signOut,
        reloadUserInfo: loadUserInfo
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
