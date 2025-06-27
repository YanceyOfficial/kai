import { authConfig } from '@/components/auth-provider'
import * as AuthSession from 'expo-auth-session'
import * as SecureStore from 'expo-secure-store'
import { isTokenExpiringSoon } from './utils'

type HttpMethod =
  | 'GET'
  | 'POST'
  | 'PUT'
  | 'PATCH'
  | 'DELETE'
  | 'HEAD'
  | 'OPTIONS'
type ResponseType = 'json' | 'text' | 'blob' | 'arrayBuffer'

interface HttpFetchOptions {
  method?: HttpMethod
  headers?: Record<string, string>
  body?: any
  query?: Record<string, string | number | boolean>
  timeout?: number
  responseType?: ResponseType
}

let cachedDiscovery: AuthSession.DiscoveryDocument | null = null

async function getDiscovery(): Promise<AuthSession.DiscoveryDocument> {
  if (cachedDiscovery) return cachedDiscovery
  const issuer = process.env.EXPO_PUBLIC_KEYCLOAK_ISSUER!
  cachedDiscovery = await AuthSession.fetchDiscoveryAsync(issuer)
  return cachedDiscovery
}

function isPlainObject(value: any): value is Record<string, any> {
  return (
    Object.prototype.toString.call(value) === '[object Object]' &&
    (value.constructor === Object || value.constructor == null)
  )
}

async function refreshToken(): Promise<boolean> {
  const refreshToken = await SecureStore.getItemAsync('refresh_token')
  if (!refreshToken) return false

  const discovery = await getDiscovery()

  try {
    const res = await AuthSession.refreshAsync(
      {
        clientId: authConfig.clientId,
        refreshToken
      },
      discovery
    )
    await SecureStore.setItemAsync('access_token', res.accessToken)
    if (res.refreshToken) {
      await SecureStore.setItemAsync('refresh_token', res.refreshToken)
    }
    return true
  } catch (e) {
    console.warn('Refresh token failed', e)
    return false
  }
}

export async function fetcher<T>(
  url: string,
  options: HttpFetchOptions = {}
): Promise<T> {
  const {
    method = 'GET',
    headers = {},
    body = null,
    query = null,
    timeout = 0,
    responseType = 'json'
  } = options

  let requestUrl = process.env.EXPO_PUBLIC_SERVER_URL + url
  if (query) {
    const queryString = new URLSearchParams(
      Object.entries(query).map(([k, v]) => [k, String(v)])
    ).toString()
    if (queryString) {
      requestUrl += (url.includes('?') ? '&' : '?') + queryString
    }
  }

  let accessToken = await SecureStore.getItemAsync('access_token')
  if (accessToken) {
    if (isTokenExpiringSoon(accessToken)) {
      const refreshed = await refreshToken()
      if (refreshed) {
        accessToken = await SecureStore.getItemAsync('access_token')
      }
    }
  }

  const fetchHeaders: Record<string, string> = {
    ...headers,
    ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {})
  }

  const fetchOptions: RequestInit = {
    method: method.toUpperCase(),
    headers: fetchHeaders
  }

  if (
    body &&
    ['POST', 'PUT', 'PATCH', 'DELETE'].includes(fetchOptions.method!)
  ) {
    const isFormData =
      typeof FormData !== 'undefined' && body instanceof FormData

    if (isFormData) {
      fetchOptions.body = body
      delete fetchHeaders['Content-Type']
      delete fetchHeaders['content-type']
    } else if (isPlainObject(body)) {
      if (!fetchHeaders['Content-Type'] && !fetchHeaders['content-type']) {
        fetchHeaders['Content-Type'] = 'application/json;charset=UTF-8'
      }
      fetchOptions.body = JSON.stringify(body)
    } else {
      fetchOptions.body = body
    }
  }

  let controller: AbortController | undefined
  let timeoutId: number | undefined
  if (timeout > 0) {
    controller = new AbortController()
    fetchOptions.signal = controller.signal
    timeoutId = setTimeout(() => controller!.abort(), timeout)
  }

  try {
    let response = await fetch(requestUrl, fetchOptions)
    if (timeoutId !== undefined) clearTimeout(timeoutId)

    // If unauthorized, try refresh and retry once
    if (response.status === 401) {
      const refreshed = await refreshToken()
      if (refreshed) {
        accessToken = await SecureStore.getItemAsync('access_token')
        fetchHeaders['Authorization'] = `Bearer ${accessToken}`
        response = await fetch(requestUrl, fetchOptions)
      }
    }

    if (!response.ok) {
      const contentType = response.headers.get('content-type') || ''
      const isJson = contentType.includes('application/json')
      let errorMessage = `HTTP ${response.status}`
      if (isJson) {
        const errData = await response.json()
        errorMessage = errData.message || JSON.stringify(errData)
      } else {
        const text = await response.text()
        if (text) errorMessage = text
      }
      throw new Error(errorMessage)
    }

    switch (responseType) {
      case 'json':
        return (await response.json()) as T
      case 'text':
        return (await response.text()) as unknown as T
      case 'blob':
        return (await response.blob()) as unknown as T
      case 'arrayBuffer':
        return (await response.arrayBuffer()) as unknown as T
      default:
        return (await response.json()) as T
    }
  } catch (err) {
    if (err instanceof Error && err.name === 'AbortError') {
      throw new Error('Request timed out')
    }
    throw err
  }
}
