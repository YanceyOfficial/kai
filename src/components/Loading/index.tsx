import classNames from 'classnames'
import LottieView from 'lottie-react-native'
import React, { FC } from 'react'
import { StyleProp, View, ViewStyle, useColorScheme } from 'react-native'

interface Props {
  style?: StyleProp<ViewStyle>
  fullScreen?: boolean
}

const Loading: FC<Props> = ({ style, fullScreen }) => {
  const isDarkMode = useColorScheme() === 'dark'

  const LoadingLottie = () => (
    <LottieView
      source={require('assets/lotties/lottie-loading.json')}
      style={[{ width: '25%', height: '25%' }, style]}
      autoPlay
      loop
    />
  )

  return (
    <>
      {fullScreen ? (
        <View
          className={classNames(
            'flex-1 items-center justify-center',
            isDarkMode ? 'bg-[#131f24]' : 'bg-#[ffffff]'
          )}
        >
          <LoadingLottie />
        </View>
      ) : (
        <LoadingLottie />
      )}
    </>
  )
}

export default Loading
