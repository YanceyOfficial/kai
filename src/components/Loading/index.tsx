import LottieView from 'lottie-react-native'
import React, { FC } from 'react'
import { StyleProp, View, ViewStyle } from 'react-native'

interface Props {
  style?: StyleProp<ViewStyle>
  fullScreen?: boolean
}

const Loading: FC<Props> = ({ style, fullScreen }) => {
  const LoadingLottie = () => (
    <LottieView
      source={require('../../../assets/lotties/lottie-loading.json')}
      style={[{ width: '25%', height: '25%' }, style]}
      autoPlay
      loop
    />
  )

  return (
    <>
      {fullScreen ? (
        <View className="flex-1 items-center justify-center">
          <LoadingLottie />
        </View>
      ) : (
        <LoadingLottie />
      )}
    </>
  )
}

export default Loading
