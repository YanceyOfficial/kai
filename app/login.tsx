import { useAuth } from '@/components/auth-provider'
import Button from '@/components/button'
import DuolingoLogoIcon from '@/components/icon/duolingo-logo-icon'
import LoginIcon from '@/components/icon/login-icon'
import SafeAreaViewWrapper from '@/components/safe-area-view-wrapper'
import React from 'react'
import { Text, View } from 'react-native'

export default function SignIn() {
  const { signIn } = useAuth()

  return (
    <SafeAreaViewWrapper hideHeader>
      <View className="flex items-center justify-center">
        <LoginIcon classNames="mt-20" />
        <DuolingoLogoIcon classNames="mt-10 mb-5" />
        <Text
          className="text-center text-lg text-[#777]"
          style={{ fontFamily: 'DINNextRoundedLTW01-Medium' }}
        >
          Learn for free. Forever.
        </Text>
      </View>
      <View>
        <Button size="small" onPress={signIn}>
          GET STARTED
        </Button>
        <Button
          color="white"
          variant="outlined"
          size="small"
          wrapperClassNames="mt-[20px]"
          onPress={signIn}
        >
          I ALREADY HAVE AN ACCOUNT
        </Button>
      </View>
    </SafeAreaViewWrapper>
  )
}
