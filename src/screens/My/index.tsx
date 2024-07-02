import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { FC } from 'react'
import { RootStackParamList } from 'shared/types'
import CMS from '../CMS'
import Error from '../Error'
import Login from '../Login'

const Stack = createNativeStackNavigator<RootStackParamList>()

const MyStack: FC = () => {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Error" component={Error} />
      <Stack.Screen name="Login" component={Login} />
      <Stack.Screen name="CMS" component={CMS} />
    </Stack.Navigator>
  )
}

export default MyStack
