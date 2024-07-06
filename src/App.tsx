import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'
import { NavigationContainer } from '@react-navigation/native'
import React, { JSX } from 'react'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import { navigationRef } from 'src/route'
import HomeIcon from './components/Icon/HomeIcon'
import MyIcon from './components/Icon/MyIcon'
import HomeStack from './screens/Home'
import MyStack from './screens/MyStack'
import { RootStackParamList } from './types'

const Tab = createBottomTabNavigator<RootStackParamList>()

const App = (): JSX.Element => {
  return (
    <SafeAreaProvider>
      <NavigationContainer ref={navigationRef}>
        <Tab.Navigator
          screenOptions={{
            headerShown: false,
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
