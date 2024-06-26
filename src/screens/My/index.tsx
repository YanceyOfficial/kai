import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { FC } from 'react'
import { RootStackParamList } from '../../shared/types'
import Login from '../Login'

const Stack = createNativeStackNavigator<RootStackParamList>()

const MyStack: FC = () => {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Login" component={Login} />
    </Stack.Navigator>
  )
}

export default MyStack
