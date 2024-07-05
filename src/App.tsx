import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'
import {
  NavigationContainer,
  createNavigationContainerRef
} from '@react-navigation/native'
import React, { JSX } from 'react'
import { useColorScheme } from 'react-native'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import HomeIcon from './components/Icon/HomeIcon'
import MyIcon from './components/Icon/MyIcon'
import HomeStack from './screens/Home'
import MyStack from './screens/MyStack'
import { RootStackParamList } from './types'

const Tab = createBottomTabNavigator<RootStackParamList>()
export const navigationRef = createNavigationContainerRef()

const App = (): JSX.Element => {
  const isDarkMode = useColorScheme() === 'dark'

  return (
    <SafeAreaProvider>
      <NavigationContainer ref={navigationRef}>
        <Tab.Navigator
          screenOptions={{
            headerShown: false,
            tabBarStyle: {
              backgroundColor: isDarkMode ? '#131f24' : '#ffffff'
            },
            tabBarShowLabel: false
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
  )
}

export default App
