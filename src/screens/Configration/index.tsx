import { NativeStackScreenProps } from '@react-navigation/native-stack'
import Button from 'components/Button'
import { FC } from 'react'
import { View } from 'react-native'
import { RootStackParamList } from 'shared/types'

type Props = NativeStackScreenProps<RootStackParamList, 'Configuration'>

const Configuration: FC<Props> = ({ navigation }) => {
  return (
    <View className="flex-1 p-4">
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
      <Button color="white" variant="outlined" wrapperClassNames="my-4">
        LOGOUT
      </Button>
    </View>
  )
}

export default Configuration
