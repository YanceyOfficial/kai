import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { FC } from 'react'
import QuizScreen from 'src/screens/Quiz'
import WordItemScreen from 'src/screens/WordItem'
import WordListScreen from 'src/screens/WordList'
import { RootStackParamList } from 'src/types'

const Stack = createNativeStackNavigator<RootStackParamList>()

const HomeStack: FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{ headerShown: false }}
      initialRouteName="WordList"
    >
      <Stack.Screen name="WordList" component={WordListScreen} />
      <Stack.Screen name="Detail" component={WordItemScreen} />
      <Stack.Screen name="Quiz" component={QuizScreen} />
    </Stack.Navigator>
  )
}

export default HomeStack
