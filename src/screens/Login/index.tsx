import { FC } from 'react'
import { View, Text, useColorScheme } from 'react-native'
import LoginIcon from '../../components/Icon/LoginIcon'
import DuolingoLogoIcon from '../../components/Icon/DuolingoLogoIcon'
import Button from '../../components/Button'
import classNames from 'classnames'
import useAuth from '../../hooks/useAuth'
import axios from 'axios'
import { TokenResponse } from '../../shared/types'
import { getData } from '../../shared/utils'

interface Props {
  navigation: any
}

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
          The free, fun, and effective way to learn a language!
        </Text>
      </View>
      <View>
        <Button onPress={handleLogin}>Get Started</Button>
        <Button
          color="white"
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
