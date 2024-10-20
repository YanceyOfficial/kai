import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'
import {
  DarkTheme,
  DefaultTheme,
  NavigationContainer
} from '@react-navigation/native'
import * as Sentry from '@sentry/react-native'
import React, { JSX } from 'react'
import { useColorScheme } from 'react-native'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import { navigationRef } from 'src/route'
import HomeIcon from './components/Icon/HomeIcon'
import MyIcon from './components/Icon/MyIcon'
import HomeStack from './screens/HomeStack'
import MyStack from './screens/MyStack'
import { RootStackParamList } from './types'

const Tab = createBottomTabNavigator<RootStackParamList>()

const App = (): JSX.Element => {
  const isDarkMode = useColorScheme() === 'dark'

  return (
    <Sentry.ErrorBoundary>
      <SafeAreaProvider>
        <NavigationContainer
          ref={navigationRef}
          theme={
            isDarkMode
              ? {
                  ...DarkTheme,
                  colors: {
                    ...DarkTheme.colors,
                    background: '#131f24',
                    border: '#37464f'
                  }
                }
              : {
                  ...DefaultTheme,
                  colors: {
                    ...DefaultTheme.colors,
                    background: '#ffffff',
                    border: '#e5e5e5'
                  }
                }
          }
        >
          <Tab.Navigator
            screenOptions={{
              headerShown: false,
              tabBarShowLabel: false,
              tabBarStyle: {
                backgroundColor: isDarkMode ? '#131f24' : '#ffffff',
                borderTopColor: isDarkMode ? '#37464f' : '#e5e5e5'
              }
            }}
            initialRouteName="Home"
          >
            <Tab.Screen
              name="Home"
              component={HomeStack}
              options={{ tabBarIcon: () => <HomeIcon width={40} /> }}
            />

            <Tab.Screen
              name="My"
              component={MyStack}
              options={{
                tabBarBadge: 3,
                tabBarIcon: () => <MyIcon width={40} />
              }}
            />
          </Tab.Navigator>
        </NavigationContainer>
      </SafeAreaProvider>
    </Sentry.ErrorBoundary>
  )
}

export default App
