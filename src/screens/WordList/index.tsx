import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import Button from 'components/Button'
import Loading from 'components/Loading'
import { FC, useEffect, useState } from 'react'
import { useColorScheme } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { Colors } from 'react-native/Libraries/NewAppScreen'
import { GET } from 'shared/axios'
import { WordList as IWordList, RootStackParamList } from 'types'

type Props = NativeStackScreenProps<RootStackParamList, 'WordList'>

const WordList: FC<Props> = ({ navigation }) => {
  const isDarkMode = useColorScheme() === 'dark'
  const isFocused = useIsFocused()
  const [dataSource, setDataSource] = useState<IWordList[] | null>(null)
  const fetchData = async () => {
    try {
      const { data } = await GET<IWordList[]>('/word')
      setDataSource(data)
    } catch (e) {}
  }

  const goToItemPage = (id: string) => {
    navigation.navigate('Detail', { id })
  }

  useEffect(() => {
    fetchData()
  }, [isFocused])

  if (!dataSource) return <Loading fullScreen />

  return (
    <SafeAreaView
      className="p-4 bg-[#131f24] flex-1"
    >
      {dataSource?.map((item) => (
        <Button
          onPress={() => goToItemPage(item._id)}
          key={item._id}
          color="blue"
          wrapperClassNames="mt-4"
        >
          {item.title.toUpperCase()}
        </Button>
      ))}
    </SafeAreaView>
  )
}

export default WordList
