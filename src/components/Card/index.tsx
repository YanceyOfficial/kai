import classNames from 'classnames'
import React, { FC, ReactNode } from 'react'
import { View } from 'react-native'

interface Props {
  children: ReactNode
  wrapperClassNames?: string
}

const Card: FC<Props> = ({ children, wrapperClassNames }) => {
  return (
    <View
      className={classNames(
        'p-5 border-2 border-b-4 border-gray-200 rounded-xl bg-white',
        wrapperClassNames
      )}
    >
      {children}
    </View>
  )
}

export default Card
