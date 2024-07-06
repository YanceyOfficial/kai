import { NativeStackScreenProps } from '@react-navigation/native-stack'
import { FC } from 'react'
import { View } from 'react-native'
import Button from 'src/components/Button'
import SafeAreaViewWrapper from 'src/components/SafeAreaViewWrapper'
import useAuth from 'src/hooks/useAuth'
import { RootStackParamList } from 'src/types'

type Props = NativeStackScreenProps<RootStackParamList, 'Configuration'>

const Configuration: FC<Props> = ({ navigation }) => {
  const { handleLogout } = useAuth()
  return (
    <SafeAreaViewWrapper wrapperClassNames="justify-start">
      <View className="mt-8">
        <Button color="blue" onPress={() => navigation.navigate('CMS')}>
          CMS
        </Button>
        <Button
          color="blue"
          wrapperClassNames="my-4"
          onPress={() => navigation.navigate('Login')}
        >
          LOGIN
        </Button>
        <Button color="blue" onPress={() => navigation.navigate('System')}>
          SYSTEM
        </Button>
        <Button
          color="white"
          variant="outlined"
          wrapperClassNames="my-4"
          onPress={handleLogout}
        >
          LOGOUT
        </Button>
      </View>
    </SafeAreaViewWrapper>
  )
}

export default Configuration
