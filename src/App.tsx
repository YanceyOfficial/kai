import {
  NavigationContainer,
  createNavigationContainerRef
} from '@react-navigation/native'
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import React, { JSX } from 'react'
import { SafeAreaView, useColorScheme } from 'react-native'
import { Colors } from 'react-native/Libraries/NewAppScreen'
import LoginScreen from './screens/Login'
import WordItemScreen from './screens/WordItem'
import WordListScreen from './screens/WordList'

const Stack = createNativeStackNavigator()
export const navigationRef = createNavigationContainerRef()

const App = (): JSX.Element => {
  const isDarkMode = useColorScheme() === 'dark'

  return (
    <SafeAreaView
      style={isDarkMode ? Colors.darker : Colors.lighter}
      className="flex-1 bg-white"
    >
      <NavigationContainer ref={navigationRef}>
        <Stack.Navigator screenOptions={{ headerShown: false }}>
          <Stack.Screen name="Home" component={WordListScreen} />
          <Stack.Screen name="Detail" component={WordItemScreen} />
          <Stack.Screen name="Login" component={LoginScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaView>
  )
}

export default App
