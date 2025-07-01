import '@/assets/styles/global.css'
import { AuthProvider, useAuth } from '@/components/auth-provider'
import { SplashScreenController } from '@/components/splash'
import { useColorScheme } from '@/hooks/use-color-scheme'
import { fetcher } from '@/shared/fetcher'
import {
  DarkTheme,
  DefaultTheme,
  ThemeProvider
} from '@react-navigation/native'
import { useFonts } from 'expo-font'
import { Stack } from 'expo-router'
import { StatusBar } from 'expo-status-bar'
import * as WebBrowser from 'expo-web-browser'
import React from 'react'
import 'react-native-reanimated'
import { SWRConfig } from 'swr'

WebBrowser.maybeCompleteAuthSession()

function RootNavigator() {
  const { userInfo } = useAuth()

  return (
    <Stack>
      <Stack.Protected guard={!!userInfo}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      </Stack.Protected>
      <Stack.Protected guard={!!userInfo}>
        <Stack.Screen name="word-detail" options={{ headerShown: false }} />
      </Stack.Protected>
        <Stack.Protected guard={!!userInfo}>
        <Stack.Screen name="quiz" options={{ headerShown: false }} />
      </Stack.Protected>
      <Stack.Protected guard={!userInfo}>
        <Stack.Screen name="login" options={{ headerShown: false }} />
      </Stack.Protected>
      <Stack.Screen name="+not-found" />
    </Stack>
  )
}

export default function RootLayout() {
  const colorScheme = useColorScheme()
  const [loaded] = useFonts({
    SpaceMono: require('../assets/fonts/SpaceMono-Regular.ttf'),
    'DINNextRoundedLTW01-Bold': require('../assets/fonts/DINNextRoundedLTW01-Bold.otf'),
    'DINNextRoundedLTW01-Light': require('../assets/fonts/DINNextRoundedLTW01-Light.otf'),
    'DINNextRoundedLTW01-Medium': require('../assets/fonts/DINNextRoundedLTW01-Medium.otf'),
    'DINNextRoundedLTW01-Regular': require('../assets/fonts/DINNextRoundedLTW01-Regular.otf')
  })

  if (!loaded) return null

  return (
    <AuthProvider>
      <SWRConfig
        value={{
          fetcher
        }}
      >
        <ThemeProvider
          value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}
        >
          <SplashScreenController />
          <RootNavigator />
          <StatusBar style="auto" />
        </ThemeProvider>
      </SWRConfig>
    </AuthProvider>
  )
}
