import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import { FC, useEffect, useState } from 'react'
import { RefreshControl, ScrollView } from 'react-native'
import Button from 'src/components/Button'
import Loading from 'src/components/Loading'
import SafeAreaViewWrapper from 'src/components/SafeAreaViewWrapper'
import { GET } from 'src/shared/axios'
import { WordList as IWordList, RootStackParamList } from 'src/types'

type Props = NativeStackScreenProps<RootStackParamList, 'WordList'>

const WordList: FC<Props> = ({ navigation }) => {
  const isFocused = useIsFocused()
  const [loading, setLoading] = useState(false)
  const [dataSource, setDataSource] = useState<IWordList[] | null>(null)
  const fetchData = async () => {
    setLoading(true)
    try {
      const { data } = await GET<IWordList[]>('/word')
      setDataSource(data)
    } catch (e) {
    } finally {
      setLoading(false)
    }
  }

  const goToItemPage = (id: string) => {
    navigation.navigate('Detail', { id })
  }

  useEffect(() => {
    fetchData()
  }, [isFocused])

  if (!dataSource) return <Loading fullScreen />

  return (
    <SafeAreaViewWrapper hideHeader>
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={loading} onRefresh={fetchData} />
        }
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
      </ScrollView>
    </SafeAreaViewWrapper>
  )
}

export default WordList
