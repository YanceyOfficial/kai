import { NativeStackScreenProps } from '@react-navigation/native-stack'
import Button from 'components/Button'
import SafeAreaViewWrapper from 'components/SafeAreaViewWrapper'
import useAuth from 'hooks/useAuth'
import { FC } from 'react'
import { RootStackParamList } from 'types'

type Props = NativeStackScreenProps<RootStackParamList, 'Configuration'>

const Configuration: FC<Props> = ({ navigation }) => {
  const { handleLogout } = useAuth()
  return (
    <SafeAreaViewWrapper>
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
    </SafeAreaViewWrapper>
  )
}

export default Configuration
