import React, { FC, ReactNode } from 'react'
import { StyleSheet, View } from 'react-native'
import Animated, {
  SharedValue,
  interpolate,
  useAnimatedStyle,
  useDerivedValue,
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

  const rotation = useDerivedValue(() =>
    withTiming(isFlipped.value ? 180 : 0, { duration })
  )

  const frontStyle = useAnimatedStyle(() => {
    const rotate = isDirectionX
      ? `${rotation.value}deg`
      : `${rotation.value}deg`

    return {
      transform: [
        { perspective: 1000 },
        isDirectionX ? { rotateX: rotate } : { rotateY: rotate }
      ],
      opacity: interpolate(rotation.value, [0, 90], [1, 0])
    }
  })

  const backStyle = useAnimatedStyle(() => {
    const rotate = isDirectionX
      ? `${rotation.value + 180}deg`
      : `${rotation.value + 180}deg`

    return {
      transform: [
        { perspective: 1000 },
        isDirectionX ? { rotateX: rotate } : { rotateY: rotate }
      ],
      opacity: interpolate(rotation.value, [90, 180], [0, 1])
    }
  })

  const styles = StyleSheet.create({
    cardContainer: {
      position: 'relative'
    },
    cardFace: {
      backfaceVisibility: 'hidden',
      position: 'absolute',
      width: '100%',
      height: '100%'
    }
  })

  return (
    <View style={styles.cardContainer}>
      <Animated.View
        className={cardStyle}
        style={[styles.cardFace, frontStyle]}
      >
        {RegularContent}
      </Animated.View>
      <Animated.View className={cardStyle} style={[styles.cardFace, backStyle]}>
        {FlippedContent}
      </Animated.View>
    </View>
  )
}

export default FlipCard
