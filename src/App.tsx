import React, { JSX } from 'react'
import { SafeAreaView, useColorScheme } from 'react-native'
import {
  createNavigationContainerRef,
  NavigationContainer
} from '@react-navigation/native'
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { Colors } from 'react-native/Libraries/NewAppScreen'
import WordList from './screens/WordList'
import LoginScreen from './screens/Login'
import WordItem from './screens/WordItem'

const Stack = createNativeStackNavigator()
export const navigationRef = createNavigationContainerRef()

const App = (): JSX.Element => {
  const isDarkMode = useColorScheme() === 'dark'

  return (
    <SafeAreaView
      style={isDarkMode ? Colors.darker : Colors.lighter}
      className="flex-1"
    >
      <NavigationContainer ref={navigationRef}>
        <Stack.Navigator screenOptions={{ headerShown: false }}>
          <Stack.Screen name="Home" component={WordList} />
          <Stack.Screen name="Detail" component={WordItem} />
          <Stack.Screen name="Login" component={LoginScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaView>
  )
}

export default App
