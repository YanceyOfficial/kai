import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'
import {
  NavigationContainer,
  createNavigationContainerRef
} from '@react-navigation/native'
import React, { JSX } from 'react'
import { SafeAreaView, useColorScheme } from 'react-native'
import { Colors } from 'react-native/Libraries/NewAppScreen'
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
    <SafeAreaView
      style={isDarkMode ? Colors.darker : Colors.lighter}
      className="flex-1"
    >
      <NavigationContainer ref={navigationRef}>
        <Tab.Navigator
          screenOptions={{
            headerShown: false
            // tabBarActiveTintColor: '#e5e7eb'
          }}
          initialRouteName="Home"
        >
          <Tab.Screen
            name="Home"
            component={HomeStack}
            options={{ tabBarIcon: () => <HomeIcon /> }}
          />

          <Tab.Screen
            name="My"
            component={MyStack}
            options={{ tabBarBadge: 3, tabBarIcon: () => <MyIcon /> }}
          />
        </Tab.Navigator>
      </NavigationContainer>
    </SafeAreaView>
  )
}

export default App
