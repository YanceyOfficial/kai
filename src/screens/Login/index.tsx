import type { NativeStackScreenProps } from '@react-navigation/native-stack'
import classNames from 'classnames'
import Button from 'components/Button'
import DuolingoLogoIcon from 'components/Icon/DuolingoLogoIcon'
import LoginIcon from 'components/Icon/LoginIcon'
import useAuth from 'hooks/useAuth'
import { FC } from 'react'
import { Text, View, useColorScheme } from 'react-native'
import { RootStackParamList } from 'shared/types'

type Props = NativeStackScreenProps<RootStackParamList, 'Login'>

const Login: FC<Props> = ({ navigation }) => {
  const toHomeScreen = () => {
    navigation.navigate('Home')
  }

  const { handleLogin } = useAuth(toHomeScreen)
  const isDarkMode = useColorScheme() === 'dark'

  return (
    <View
      className={classNames(
        'px-[20px] flex-1 justify-between py-4 pt-[90px]',
        isDarkMode ? 'bg-black' : 'bg-white'
      )}
    >
      <View className="flex justify-center items-center">
        <LoginIcon />
        <DuolingoLogoIcon classNames="mt-[40px] mb-5" />
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
    </View>
  )
}

export default Login
