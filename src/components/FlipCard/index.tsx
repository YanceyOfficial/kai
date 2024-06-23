import React, { FC, ReactNode } from 'react'
import { StyleSheet, View } from 'react-native'
import Animated, {
  SharedValue,
  interpolate,
  useAnimatedStyle,
  withTiming
} from 'react-native-reanimated'

interface Props {
  isFlipped: SharedValue<boolean>
  cardStyle: string
  direction?: 'x' | 'y'
  duration?: number
  RegularContent: ReactNode
  FlippedContent: ReactNode
}

const FlipCard: FC<Props> = ({
  isFlipped,
  cardStyle,
  direction = 'y',
  duration = 500,
  RegularContent,
  FlippedContent
}) => {
  const isDirectionX = direction === 'x'

  const regularCardAnimatedStyle = useAnimatedStyle(() => {
    const spinValue = interpolate(Number(isFlipped.value), [0, 1], [0, 180])
    const rotateValue = withTiming(`${spinValue}deg`, { duration })

    return {
      transform: [
        isDirectionX ? { rotateX: rotateValue } : { rotateY: rotateValue }
      ]
    }
  })

  const flippedCardAnimatedStyle = useAnimatedStyle(() => {
    const spinValue = interpolate(Number(isFlipped.value), [0, 1], [180, 360])
    const rotateValue = withTiming(`${spinValue}deg`, { duration })

    return {
      transform: [
        isDirectionX ? { rotateX: rotateValue } : { rotateY: rotateValue }
      ]
    }
  })

  const flipCardStyles = StyleSheet.create({
    regularCard: {
      position: 'absolute',
      zIndex: 1
    },
    flippedCard: {
      backfaceVisibility: 'hidden',
      zIndex: 2
    }
  })

  return (
    <View>
      <Animated.View
        className={cardStyle}
        style={[flipCardStyles.regularCard, regularCardAnimatedStyle]}
      >
        {RegularContent}
      </Animated.View>
      <Animated.View
        className={cardStyle}
        style={[flipCardStyles.flippedCard, flippedCardAnimatedStyle]}
      >
        {FlippedContent}
      </Animated.View>
    </View>
  )
}

export default FlipCard
