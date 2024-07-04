import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { FC } from 'react'
import Configration from 'screens/Configration'
import System from 'screens/System'
import { RootStackParamList } from 'types'
import CMS from '../CMS'
import Error from '../Error'
import Login from '../Login'

const Stack = createNativeStackNavigator<RootStackParamList>()

const MyStack: FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{ headerShown: false }}
      initialRouteName="Configuration"
    >
      <Stack.Screen name="Configuration" component={Configration} />
      <Stack.Screen name="CMS" component={CMS} />
      <Stack.Screen name="Error" component={Error} />
      <Stack.Screen name="Login" component={Login} />
      <Stack.Screen name="System" component={System} />
    </Stack.Navigator>
  )
}

export default MyStack
