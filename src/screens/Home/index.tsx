import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { FC } from 'react'
import { RootStackParamList } from 'shared/types'
import WordItemScreen from '../WordItem'
import WordList from '../WordList'

const Stack = createNativeStackNavigator<RootStackParamList>()

const HomeStack: FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{ headerShown: false }}
      initialRouteName="WordList"
    >
      <Stack.Screen name="WordList" component={WordList} />
      <Stack.Screen name="Detail" component={WordItemScreen} />
    </Stack.Navigator>
  )
}

export default HomeStack
