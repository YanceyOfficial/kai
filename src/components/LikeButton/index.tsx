import React, { FC } from 'react'
import { Pressable, StyleSheet } from 'react-native'
import Animated, {
  Extrapolation,
  interpolate,
  useAnimatedStyle,
  useSharedValue,
  withSpring
} from 'react-native-reanimated'
import Icon from 'react-native-vector-icons/MaterialCommunityIcons'

interface Props {
  onPress: () => void
}

const LikeButton: FC<Props> = ({ onPress }) => {
  const liked = useSharedValue(0)

  const outlineStyle = useAnimatedStyle(() => {
    return {
      transform: [
        {
          scale: interpolate(liked.value, [0, 1], [1, 0], Extrapolation.CLAMP)
        }
      ]
    }
  })

  const fillStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: liked.value }],
      opacity: liked.value
    }
  })

  const handlePress = () => {
    liked.value = withSpring(liked.value ? 0 : 1)
    onPress()
  }

  return (
    <Pressable onPress={handlePress}>
      <Animated.View style={[StyleSheet.absoluteFillObject, outlineStyle]}>
        <Icon name={'star-plus-outline'} size={28} color={'#ADADAD'} />
      </Animated.View>

      <Animated.View style={fillStyle}>
        <Icon name={'star-plus'} size={28} color={'#FF4B4B'} />
      </Animated.View>
    </Pressable>
  )
}

export default LikeButton
