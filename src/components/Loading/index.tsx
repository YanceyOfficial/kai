import LottieView from 'lottie-react-native'
import React, { FC } from 'react'
import { View } from 'react-native'

const Loading: FC = () => {
  return (
    <View className="flex items-center justify-center">
      <LottieView
        source={require('../../../assets/lotties/lottie-loading.json')}
        style={{ width: '50%', height: '100%' }}
        autoPlay
        loop
      />
    </View>
  )
}

export default Loading
