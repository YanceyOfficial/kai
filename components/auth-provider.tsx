import { OAUTH_REDIRECT_URL } from '@/shared/constants'
import type { UserInfo } from '@/shared/types'
import * as AuthSession from 'expo-auth-session'
import * as SecureStore from 'expo-secure-store'
import {
  createContext,
  ReactNode,
  use,
  useCallback,
  useEffect,
  useState
} from 'react'

const authConfig = {
  clientId: process.env.EXPO_PUBLIC_KEYCLOAK_CLIENT_ID,
  redirectUri: AuthSession.makeRedirectUri({
    scheme: OAUTH_REDIRECT_URL
  })
}

const AuthContext = createContext<{
  userInfo: UserInfo | null
  loading: boolean
  signIn: (
    options?: AuthSession.AuthRequestPromptOptions
  ) => Promise<AuthSession.AuthSessionResult>
  signOut: () => Promise<void>
  reloadUserInfo: () => Promise<void>
  updateRefreshToken: () => Promise<void>
} | null>(null)

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [loading, setLoading] = useState(true)
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null)
  const discovery = AuthSession.useAutoDiscovery(
    process.env.EXPO_PUBLIC_KEYCLOAK_ISSUER
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

  const updateRefreshToken = async () => {
    const refreshToken = await SecureStore.getItemAsync('refresh_token')
    if (!refreshToken || !discovery) return

    const result = await AuthSession.refreshAsync(
      {
        clientId: process.env.EXPO_PUBLIC_KEYCLOAK_CLIENT_ID,
        refreshToken
      },
      discovery
    )

    await SecureStore.setItemAsync('access_token', result.accessToken)
    await SecureStore.setItemAsync('refresh_token', result.refreshToken ?? '')
  }

  const loadUserInfo = useCallback(async () => {
    const accessToken = await SecureStore.getItemAsync('access_token')
    if (!accessToken || !discovery) return

    try {
      const response = (await AuthSession.fetchUserInfoAsync(
        { accessToken },
        discovery
      )) as UserInfo
      setUserInfo(response)
    } catch (e) {
      console.log(e)
      setUserInfo(null)
    } finally {
      setLoading(false)
    }
  }, [discovery])

  const exchangeCodeToToken = useCallback(async () => {
    if (discovery && response?.type === 'success') {
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
      await SecureStore.setItemAsync(
        'refresh_token',
        tokenResult.refreshToken ?? ''
      )
      loadUserInfo()
    }
  }, [discovery, loadUserInfo, request?.codeVerifier, response])

  const signOut = async () => {
    await SecureStore.deleteItemAsync('access_token')
    await SecureStore.deleteItemAsync('refresh_token')
    setUserInfo(null)
  }

  // After Sign-in
  useEffect(() => {
    exchangeCodeToToken()
  }, [exchangeCodeToToken, response])

  // After launching APP
  useEffect(() => {
    const accessToken = SecureStore.getItem('access_token')
    if (accessToken) {
      loadUserInfo()
    }
  }, [loadUserInfo])

  return (
    <AuthContext
      value={{
        userInfo,
        loading,
        updateRefreshToken,
        signIn: promptAsync,
        signOut,
        reloadUserInfo: loadUserInfo
      }}
    >
      {children}
    </AuthContext>
  )
}

export function useAuth() {
  const value = use(AuthContext)
  if (!value) {
    throw new Error('useSession must be wrapped in a <SessionProvider />')
  }

  return value
}
