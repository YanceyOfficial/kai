import { useNavigation } from '@react-navigation/native'
import classNames from 'classnames'
import { FC, ReactNode } from 'react'
import { Pressable, View, useColorScheme } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import CloseIcon from 'src/components/Icon/CloseIcon'

interface Props {
  children: ReactNode
  hideHeader?: boolean
  customHeader?: ReactNode
  headerRightComp?: ReactNode
  wrapperClassNames?: string
  headerWrapperClassNames?: string
  onClose?: () => void
}

const SafeAreaViewWrapper: FC<Props> = ({
  hideHeader,
  headerWrapperClassNames,
  wrapperClassNames,
  customHeader,
  headerRightComp,
  children,
  onClose
}) => {
  const isDarkMode = useColorScheme() === 'dark'
  const navigation = useNavigation()

  const handleClose = () => {
    if (typeof onClose === 'function') {
      onClose()
    } else {
      navigation.goBack()
    }
  }

  const renderHeader = () => {
    if (hideHeader) return null

    return (
      <View
        className={classNames(
          'flex flex-row items-center',
          headerWrapperClassNames
        )}
      >
        {customHeader ? (
          customHeader
        ) : (
          <>
            <Pressable onPress={handleClose}>
              <CloseIcon />
            </Pressable>
            {headerRightComp ? headerRightComp : null}
          </>
        )}
      </View>
    )
  }

  return (
    <SafeAreaView
      className={classNames(
        'flex-1 p-4 justify-between',
        isDarkMode ? 'bg-[#131f24]' : 'bg-white',
        wrapperClassNames
      )}
    >
      {renderHeader()}
      {children}
    </SafeAreaView>
  )
}

export default SafeAreaViewWrapper
