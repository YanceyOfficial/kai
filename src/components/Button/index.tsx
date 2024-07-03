import classNames from 'classnames'
import useAudioPlayer from 'hooks/useAudioPlayer'
import React, { FC, ReactNode } from 'react'
import { Pressable, Text } from 'react-native'
import { trigger } from 'react-native-haptic-feedback'
import Loading from '../Loading'
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
  children: ReactNode
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
  loading = false,
  selected = false,
  soundSource,
  onPress,
  wrapperClassNames,
  textClassNames
}) => {
  const diasblePressingEffect = disabled || loading || selected
  const { handleAudioFromLocalFile } = useAudioPlayer()

  const handlePress = () => {
    if (disabled) return

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
        'p-4 justify-center items-center',
        {
          'active:shadow-none active:translate-y-[4px]': !diasblePressingEffect
        },
        wrapperStyles[color],
        sizeStyles[size].wrapper,
        { [outlinedStyles[color]]: variant === 'outlined' },
        { [wrapperDisabledStyles]: disabled },
        { [wrapperSelectedStyles]: selected },
        wrapperClassNames
      )}
      onPress={handlePress}
    >
      {loading ? (
        <Loading style={{ width: '100%', height: 17.3 }} />
      ) : typeof children === 'object' ? (
        <>{children}</>
      ) : (
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
      )}
    </Pressable>
  )
}

export default Button
