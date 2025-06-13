import { cn } from '@/shared/utils'
import React, { ReactNode } from 'react'
import { StyleProp, View, ViewStyle, useColorScheme } from 'react-native'

export function WordCard({
  children,
  wrapperClassNames,
  wrapperStyles
}: {
  children: ReactNode
  wrapperClassNames?: string
  wrapperStyles?: StyleProp<ViewStyle>
}) {
  const isDarkMode = useColorScheme() === 'dark'

  return (
    <View
      className={cn(
        'rounded-xl border-2 border-b-4 p-5',
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
