import classNames from 'classnames'
import React, { FC, ReactNode } from 'react'
import { View, useColorScheme } from 'react-native'

interface Props {
  children: ReactNode
  wrapperClassNames?: string
}

const Card: FC<Props> = ({ children, wrapperClassNames }) => {
  const isDarkMode = useColorScheme() === 'dark'
  return (
    <View
      className={classNames(
        'p-5 border-2 border-b-4  rounded-xl ',
        isDarkMode
          ? 'border-[#37464f] bg-[#131f24]'
          : 'border-[#e5e5e5] bg-white',
        wrapperClassNames
      )}
    >
      {children}
    </View>
  )
}

export default Card
