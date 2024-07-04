import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { FC } from 'react'
import QuizScreen from 'screens/Quiz'
import WordItemScreen from 'screens/WordItem'
import WordList from 'screens/WordList'
import { RootStackParamList } from 'types'

const Stack = createNativeStackNavigator<RootStackParamList>()

const HomeStack: FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{ headerShown: false }}
      initialRouteName="WordList"
    >
      <Stack.Screen name="WordList" component={WordList} />
      <Stack.Screen name="Detail" component={WordItemScreen} />
      <Stack.Screen name="Quiz" component={QuizScreen} />
    </Stack.Navigator>
  )
}

export default HomeStack
