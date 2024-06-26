import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'
import {
  NavigationContainer,
  createNavigationContainerRef
} from '@react-navigation/native'
import React, { JSX } from 'react'
import { SafeAreaView, useColorScheme } from 'react-native'
import { Colors } from 'react-native/Libraries/NewAppScreen'
import LoginScreen from './screens/Login'
import WordItemScreen from './screens/WordItem'
import WordListScreen from './screens/WordList'
import { RootStackParamList } from './shared/types'
import MyScreen from './screens/My'

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
        <Tab.Navigator screenOptions={{ headerShown: false }}>
          <Tab.Screen name="Home" component={WordListScreen} />
          <Tab.Screen name="Detail" component={WordItemScreen} />
          <Tab.Screen name="Login" component={LoginScreen} />
          <Tab.Screen name="My" component={MyScreen} />
        </Tab.Navigator>
      </NavigationContainer>
    </SafeAreaView>
  )
}

export default App
