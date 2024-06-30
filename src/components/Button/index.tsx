import classNames from 'classnames'
import React, { FC } from 'react'
import { Pressable, Text } from 'react-native'
import { trigger } from 'react-native-haptic-feedback'
import useAudioPlayer from '../../hooks/useAudioPlayer'
import {
  fontFamilyStyles,
  outlinedStyles,
  sizeStyles,
  textDisabledStyles,
  textSelectedStyles,
  textStyles,
  wrapperDisabledStyles,
  wrapperSelectedStyles,
  wrapperStyles
} from './styles'

interface Props {
  variant?: 'outlined' | 'contained'
  size?: 'small' | 'large'
  children: string
  color?: 'green' | 'white' | 'blue' | 'red'
  loading?: boolean
  disabled?: boolean
  selected?: boolean
  soundSource?: string
  onPress?: () => void
  wrapperClassNames?: string
  textClassNames?: string
}

const Button: FC<Props> = ({
  variant = 'contained',
  color = 'green',
  size = 'small',
  children = '',
  disabled = false,
  selected = false,
  soundSource,
  onPress,
  wrapperClassNames,
  textClassNames
}) => {
  const { handleAudioFromLocalFile } = useAudioPlayer()

  const handlePress = () => {
    trigger('impactLight', {
      enableVibrateFallback: true,
      ignoreAndroidSystemSettings: false
    })

    if (onPress) {
      if (soundSource) {
        handleAudioFromLocalFile(soundSource)
      }
      onPress()
    }
  }
  return (
    <Pressable
      className={classNames(
        'w-full py-4 flex justify-center items-center active:shadow-none active:translate-y-[4px]',
        wrapperStyles[color],
        sizeStyles[size].wrapper,
        { [outlinedStyles[color]]: variant === 'outlined' },
        { [wrapperDisabledStyles]: disabled },
        { [wrapperSelectedStyles]: selected },
        wrapperClassNames
      )}
      onPress={handlePress}
    >
      <Text
        className={classNames(
          textStyles[color],
          sizeStyles[size].text,
          { [textDisabledStyles]: disabled },
          { [textSelectedStyles]: selected },
          textClassNames
        )}
        style={fontFamilyStyles[size]}
      >
        {children}
      </Text>
    </Pressable>
  )
}

export default Button
