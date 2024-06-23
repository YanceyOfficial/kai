import axios, { AxiosResponse } from 'axios'
import Config from 'react-native-config'
import { navigationRef } from '../App'
import { TokenResponse } from './types'
import { getData } from './utils'

axios.defaults.timeout = 5 * 10000
axios.defaults.headers['Content-Type'] = 'application/json'
axios.defaults.baseURL = Config.SERVICE_URL
axios.interceptors.request.use(
  async (config) => {
    const token = await getData<TokenResponse>('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token?.accessToken}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)
axios.interceptors.response.use(
  function (response) {
    if (response.status === 401) {
      if (navigationRef.isReady()) {
        navigationRef.navigate('Login')
      }
    }
    return response
  },
  function (error) {
    // Any status codes that falls outside the range of 2xx cause this function to trigger
    // Do something with response error
    return Promise.reject(error)
  }
)

export const GET = <T, K = undefined>(
  url: string,
  params?: K
): Promise<AxiosResponse<T>> => {
  return new Promise((resolve, reject) => {
    axios
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
    axios
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
    axios
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
    axios
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
    axios
      .delete(url, { data: params })
      .then((res) => {
        resolve(res)
      })
      .catch((err) => {
        reject(err)
      })
  })
}
