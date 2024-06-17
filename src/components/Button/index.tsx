import React, { FC, ReactNode } from 'react'
import { Pressable, Text } from 'react-native'
import { trigger } from 'react-native-haptic-feedback'
import classNames from 'classnames'


interface Props {
  type: 'contained' | 'outlined'
  children: ReactNode
  onClick?: () => void
  wrapperClassNames?: string;
  textClassNames?: string;
}

const wrapperStyles = {
  contained: 'bg-[#58cc02] shadow-duolingoGreen',
  outlined: 'bg-white shadow-duolingoWhite'
}

const textStyles = {
  contained: 'text-white',
  outlined: 'color-[#4b4b4b]'
}

const Button: FC<Props> = ({ type, children, onClick, wrapperClassNames, textClassNames }) => {
  const onPress = () => {
    trigger('impactLight', {
      enableVibrateFallback: true,
      ignoreAndroidSystemSettings: false
    })

    if (onClick) {
      onClick()
    }
  }
  return (
    <Pressable
      className={classNames("w-full rounded-xl py-4 flex justify-center items-center relative active:shadow-none active:translate-y-[4px]", wrapperStyles[type], wrapperClassNames)}
      onPress={onPress}
    >
      <Text className={classNames("text-base font-bold", textStyles[type], textClassNames)}>{children}</Text>
    </Pressable>
  )
}

export default Button
