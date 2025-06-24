import { SplashScreen } from 'expo-router'
import { useAuth } from './auth-provider'

export function SplashScreenController() {
  const { loading } = useAuth()

  if (!loading) {
    SplashScreen.hideAsync()
  }

  return null
}
