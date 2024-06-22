import React, { FC, ReactNode } from 'react'
import { Pressable, Text } from 'react-native'
import { trigger } from 'react-native-haptic-feedback'
import classNames from 'classnames'

interface Props {
  color: 'green' | 'white' | 'blue'
  children: string
  onPress?: () => void
  wrapperClassNames?: string
  textClassNames?: string
}

const wrapperStyles = {
  green: 'bg-[#58cc02] shadow-duolingoGreen',
  white: 'bg-white shadow-duolingoWhite',
  blue: 'bg-[#49c0f8] shadow-duolingoBlue'
}

const textStyles = {
  green: 'text-white',
  white: 'color-[#1cb0f6]',
  blue: 'color-[#131f64]'
}

const Button: FC<Props> = ({
  color,
  children,
  onPress,
  wrapperClassNames,
  textClassNames
}) => {
  const handlePress = () => {
    trigger('impactLight', {
      enableVibrateFallback: true,
      ignoreAndroidSystemSettings: false
    })

    if (onPress) {
      onPress()
    }
  }
  return (
    <Pressable
      className={classNames(
        'w-full rounded-xl py-4 flex justify-center items-center active:shadow-none active:translate-y-[4px]',
        wrapperStyles[color],
        wrapperClassNames
      )}
      onPress={handlePress}
    >
      <Text
        className={classNames('text-lg', textStyles[color], textClassNames)}
        style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
      >
        {children.toUpperCase()}
      </Text>
    </Pressable>
  )
}

export default Button
