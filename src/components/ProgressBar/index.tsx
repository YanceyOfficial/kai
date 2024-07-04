import classNames from 'classnames'
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
  wrapperClassNames?: string
}

const ProgressBar: FC<Props> = ({ progress, wrapperClassNames }) => {
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
    <View
      className={classNames(
        'flex-1 bg-[#e5e5e5] rounded-lg h-4',
        wrapperClassNames
      )}
    >
      <Animated.View
        className={`bg-[#58cc02] h-4 rounded-3xl relative`}
        style={progressBarWidthAnimated}
        onLayout={(event) => {
          const { width } = event.nativeEvent.layout
          setWidth(width)
        }}
      >
        <View
          className="bg-[#fff] h-[6px] rounded-lg top-1 left-[8px] opacity-20"
          style={{ width: width - 16 <= 0 ? 0 : width - 16 }}
        />
      </Animated.View>
    </View>
  )
}

export default ProgressBar
