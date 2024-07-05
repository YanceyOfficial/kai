import { NativeStackScreenProps } from '@react-navigation/native-stack'
import Button from 'components/Button'
import useAuth from 'hooks/useAuth'
import { FC } from 'react'
import { View } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { RootStackParamList } from 'types'

type Props = NativeStackScreenProps<RootStackParamList, 'Configuration'>

const Configuration: FC<Props> = ({ navigation }) => {
  const { handleLogout } = useAuth()
  return (
    <SafeAreaView className="flex-1 p-4">
      <Button color="blue" onPress={() => navigation.replace('CMS')}>
        CMS
      </Button>
      <Button
        color="blue"
        wrapperClassNames="my-4"
        onPress={() => navigation.replace('Login')}
      >
        LOGIN
      </Button>
      <Button color="blue" onPress={() => navigation.replace('System')}>
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
    </SafeAreaView>
  )
}

export default Configuration
