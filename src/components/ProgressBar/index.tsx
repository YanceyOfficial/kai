import { FC, useState } from 'react'
import { DimensionValue, View } from 'react-native'
import Animated, {
  AnimatableValue,
  Easing,
  useAnimatedStyle,
  withTiming
} from 'react-native-reanimated'

interface Props {
  progress: AnimatableValue
}

const ProgressBar: FC<Props> = ({ progress }) => {
  const [width, setWidth] = useState(0)

  const progressBarWidthAnimated = useAnimatedStyle(
    () => ({
      width: withTiming(progress, {
        duration: 250,
        easing: Easing.bounce
      }) as DimensionValue
    }),
    [progress]
  )

  return (
    <View className="flex-1 bg-[#E5E5E5] rounded-3xl h-5 mx-4">
      <Animated.View
        className={`bg-[#93d333] h-5 rounded-3xl relative`}
        style={progressBarWidthAnimated}
        onLayout={(event) => {
          const { width } = event.nativeEvent.layout
          setWidth(width)
        }}
      >
        <View
          className="bg-[#fff] h-[6px] rounded top-1 left-[8px] opacity-20"
          style={{ width: width - 16 }}
        />
      </Animated.View>
    </View>
  )
}

export default ProgressBar
