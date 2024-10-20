import type { NativeStackScreenProps } from '@react-navigation/native-stack'
import { FC } from 'react'
import { Text, View } from 'react-native'
import Button from 'src/components/Button'
import DuolingoLogoIcon from 'src/components/Icon/DuolingoLogoIcon'
import LoginIcon from 'src/components/Icon/LoginIcon'
import SafeAreaViewWrapper from 'src/components/SafeAreaViewWrapper'
import useAuth from 'src/hooks/useAuth'
import useHideBottomTab from 'src/hooks/useHideBottomTab'
import { RootStackParamList } from 'src/types'

type Props = NativeStackScreenProps<RootStackParamList, 'Login'>

const Login: FC<Props> = ({ navigation }) => {
  useHideBottomTab(navigation)

  const toHomeScreen = () => {
    navigation.replace('WordList')
  }

  const { handleLogin } = useAuth(toHomeScreen)

  return (
    <SafeAreaViewWrapper hideHeader>
      <View className="flex justify-center items-center">
        <LoginIcon classNames="mt-20" />
        <DuolingoLogoIcon classNames="mt-10 mb-5" />
        <Text
          className="text-[#777] text-lg text-center"
          style={{ fontFamily: 'DINNextRoundedLTW01-Medium' }}
        >
          Learn for free. Forever.
        </Text>
      </View>
      <View>
        <Button size="small" onPress={handleLogin}>
          GET STARTED
        </Button>
        <Button
          color="white"
          variant="outlined"
          size="small"
          wrapperClassNames="mt-[20px]"
          onPress={handleLogin}
        >
          I ALREADY HAVE AN ACCOUNT
        </Button>
      </View>
    </SafeAreaViewWrapper>
  )
}

export default Login
