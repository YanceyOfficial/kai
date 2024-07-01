import axios, { AxiosError, AxiosResponse } from 'axios'
import { refresh } from 'react-native-app-auth'
import Config from 'react-native-config'
import { navigationRef } from '../App'
import { keycloak } from '../hooks/useAuth'
import { TOKEN_EXPIRED_MIN_VALIDITY } from './constants'
import { RootStackParamList } from './types'
import { getSecureValue, setSecureTokens } from './utils'

const axiosInstance = axios.create({
  baseURL: Config.SERVICE_URL,
  headers: {
    'Content-Type': 'application/json'
  },
  timeout: 5000
})

axiosInstance.interceptors.request.use(
  async (config) => {
    let accessToken = await getSecureValue('accessToken')

    if (!accessToken) {
      if (navigationRef.isReady()) {
        // @ts-ignore
        navigationRef.navigate<keyof RootStackParamList>('My')
      }
    } else {
      const accessTokenExpirationDate = await getSecureValue(
        'accessTokenExpirationDate'
      )

      if (accessTokenExpirationDate) {
        const accessTokenExpirationTimestamp = +new Date(
          accessTokenExpirationDate
        )
        const nowTimeStamp = +new Date()
        const refreshToken = await getSecureValue('refreshToken')

        if (!refreshToken) {
          if (navigationRef.isReady()) {
            // @ts-ignore
            navigationRef.navigate<keyof RootStackParamList>('My')
          }
        } else {
          if (
            // Access token has already expired.
            accessTokenExpirationTimestamp >= nowTimeStamp ||
            // Access token will expire within TOKEN_EXPIRED_MIN_VALIDITY.
            accessTokenExpirationTimestamp - nowTimeStamp <=
              TOKEN_EXPIRED_MIN_VALIDITY
          ) {
            try {
              const newTokens = await refresh(keycloak, {
                refreshToken
              })

              accessToken = newTokens.accessToken
              await setSecureTokens(newTokens)
            } catch (e) {
              if (navigationRef.isReady()) {
                // @ts-ignore
                navigationRef.navigate<keyof RootStackParamList>('My')
              }
            }
          }
        }
      }

      config.headers.Authorization = `Bearer ${accessToken}`
    }

    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

axiosInstance.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      console.log('axiosInstance.interceptors.response error', error.response)
      if (navigationRef.isReady()) {
        // @ts-ignore
        navigationRef.navigate<keyof RootStackParamList>('My')
      }
    }
    return Promise.reject(error)
  }
)

export const GET = <T, K = undefined>(
  url: string,
  params?: K
): Promise<AxiosResponse<T>> => {
  return new Promise((resolve, reject) => {
    axiosInstance
      .get(url, { params })
      .then((res) => {
        resolve(res)
      })
      .catch((err) => {
        reject(err)
      })
  })
}

export const POST = <T, K>(
  url: string,
  params?: K
): Promise<AxiosResponse<T>> => {
  return new Promise((resolve, reject) => {
    axiosInstance
      .post(url, params)
      .then(
        (res) => {
          resolve(res)
        },
        (err) => {
          reject(err)
        }
      )
      .catch((err) => {
        reject(err)
      })
  })
}

export const PUT = <T, K>(
  url: string,
  params?: K
): Promise<AxiosResponse<T>> => {
  return new Promise((resolve, reject) => {
    axiosInstance
      .put(url, params)
      .then((res) => {
        resolve(res)
      })
      .catch((err) => {
        reject(err)
      })
  })
}

export const PATCH = <T, K>(
  url: string,
  params?: K
): Promise<AxiosResponse<T>> => {
  return new Promise((resolve, reject) => {
    axiosInstance
      .patch(url, params)
      .then((res) => {
        resolve(res)
      })
      .catch((err) => {
        reject(err)
      })
  })
}

export const DELETE = <T, K>(
  url: string,
  params?: K
): Promise<AxiosResponse<T>> => {
  return new Promise((resolve, reject) => {
    axiosInstance
      .delete(url, { data: params })
      .then((res) => {
        resolve(res)
      })
      .catch((err) => {
        reject(err)
      })
  })
}
