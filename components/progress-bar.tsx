import { cn } from '@/shared/utils'
import { FC, useState } from 'react'
import { DimensionValue, View, useColorScheme } from 'react-native'
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
  const isDarkMode = useColorScheme() === 'dark'
  const [width, setWidth] = useState(0)

  const progressBarWidthAnimated = useAnimatedStyle(
    () => ({
      width: withTiming(progress, {
        duration: 250,
        easing: Easing.bounce
      }) as DimensionValue,
      display:
        Number((progress as string).replace('%', '')) < 4 ? 'none' : 'flex'
    }),
    [progress]
  )

  return (
    <View
      className={cn(
        'h-4 flex-1 rounded-lg',
        isDarkMode ? 'bg-[#37464f]' : 'bg-[#e5e5e5]',
        wrapperClassNames
      )}
    >
      <Animated.View
        className={cn(
          'relative h-4 rounded-3xl',
          isDarkMode ? 'bg-[#93d333]' : 'bg-[#58cc02]'
        )}
        style={progressBarWidthAnimated}
        onLayout={(event) => {
          const { width } = event.nativeEvent.layout
          setWidth(width)
        }}
      >
        <View
          className="left-[8px] top-1 h-[6px] rounded-lg bg-white opacity-20"
          style={{ width: width - 16 <= 0 ? 0 : width - 16 }}
        />
      </Animated.View>
    </View>
  )
}

export default ProgressBar
