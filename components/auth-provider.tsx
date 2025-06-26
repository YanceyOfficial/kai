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
  useRef,
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
} | null>(null)

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const timer = useRef<number | null>(null)
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

  const updateRefreshToken = useCallback(async () => {
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
  }, [discovery])

  const loadUserInfo = useCallback(async () => {
    const accessToken = await SecureStore.getItemAsync('access_token')
    if (!accessToken || !discovery) return

    try {
      const response = (await AuthSession.fetchUserInfoAsync(
        { accessToken },
        discovery
      )) as UserInfo
      setUserInfo(response)

      timer.current = setInterval(() => {
        updateRefreshToken()
      }, 10_000)
    } catch {
      setUserInfo(null)
    } finally {
      setLoading(false)
    }
  }, [discovery, updateRefreshToken])

  const signOut = async () => {
    await SecureStore.deleteItemAsync('access_token')
    await SecureStore.deleteItemAsync('refresh_token')
    setUserInfo(null)
  }

  // After Sign-in
  useEffect(() => {
    if (discovery && response?.type === 'success') {
      AuthSession.exchangeCodeAsync(
        {
          ...authConfig,
          code: response.params.code,
          extraParams: {
            code_verifier: request?.codeVerifier ?? ''
          }
        },
        discovery
      ).then((tokenResult) => {
        SecureStore.setItem('access_token', tokenResult.accessToken)
        SecureStore.setItem('refresh_token', tokenResult.refreshToken ?? '')
        loadUserInfo()
      })
    }

    return () => {
      if (timer.current) {
        clearInterval(timer.current)
      }
    }
  }, [discovery, loadUserInfo, request?.codeVerifier, response])

  // After launching APP if exist access token
  useEffect(() => {
    const accessToken = SecureStore.getItem('access_token')
    if (accessToken) {
      loadUserInfo()
    }

    return () => {
      if (timer.current) {
        clearInterval(timer.current)
      }
    }
  }, [loadUserInfo])

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
  const value = use(AuthContext)
  if (!value) {
    throw new Error('useSession must be wrapped in a <SessionProvider />')
  }

  return value
}
