import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { FC } from 'react'
import CmsScreen from 'src/screens/CMS'
import ConfigurationScreen from 'src/screens/Configuration'
import ErrorScreen from 'src/screens/Error'
import LoginScreen from 'src/screens/Login'
import SystemScreen from 'src/screens/System'
import { RootStackParamList } from 'src/types'

const Stack = createNativeStackNavigator<RootStackParamList>()

const MyStack: FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{ headerShown: false }}
      initialRouteName="Configuration"
    >
      <Stack.Screen name="Configuration" component={ConfigurationScreen} />
      <Stack.Screen name="CMS" component={CmsScreen} />
      <Stack.Screen name="Error" component={ErrorScreen} />
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="System" component={SystemScreen} />
    </Stack.Navigator>
  )
}

export default MyStack
