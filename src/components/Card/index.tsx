import classNames from 'classnames'
import React, { FC, ReactNode } from 'react'
import { StyleProp, View, ViewStyle, useColorScheme } from 'react-native'

interface Props {
  children: ReactNode
  wrapperClassNames?: string
  wrapperStyles?: StyleProp<ViewStyle>
}

const Card: FC<Props> = ({ children, wrapperClassNames, wrapperStyles }) => {
  const isDarkMode = useColorScheme() === 'dark'

  return (
    <View
      className={classNames(
        'p-5 border-2 border-b-4 rounded-xl',
        isDarkMode
          ? 'border-[#37464f] bg-[#131f24]'
          : 'border-[#e5e5e5] bg-white',
        wrapperClassNames
      )}
      style={wrapperStyles}
    >
      {children}
    </View>
  )
}

export default Card
