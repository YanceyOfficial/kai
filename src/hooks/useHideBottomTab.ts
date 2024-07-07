import { NativeStackNavigationProp } from '@react-navigation/native-stack'
import { useEffect } from 'react'
import { useColorScheme } from 'react-native'
import { RootStackParamList } from 'src/types'

const useHideBottomTab = (
  navigation: NativeStackNavigationProp<
    RootStackParamList,
    keyof RootStackParamList
  >
) => {
  const isDarkMode = useColorScheme() === 'dark'

  useEffect(() => {
    navigation.getParent()?.setOptions({ tabBarStyle: { display: 'none' } })
    return () =>
      navigation.getParent()?.setOptions({
        tabBarStyle: {
          display: 'flex',
          position: 'absolute',
          backgroundColor: isDarkMode ? '#131f24' : '#ffffff',
          borderTopColor: isDarkMode ? '#37464f' : '#e5e5e5'
        }
      })
  }, [])
}

export default useHideBottomTab
