import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import { FC, useEffect, useState } from 'react'
import { RefreshControl, ScrollView } from 'react-native'
import Button from 'src/components/Button'
import Loading from 'src/components/Loading'
import SafeAreaViewWrapper from 'src/components/SafeAreaViewWrapper'
import { GET } from 'src/shared/axios'
import {
  WordList as IWordList,
  Pagination,
  RootStackParamList
} from 'src/types'

type Props = NativeStackScreenProps<RootStackParamList, 'WordList'>

const WordList: FC<Props> = ({ navigation }) => {
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(false)
  const fetchData = async () => {
    setLoading(true)
    try {
      const { data } = await GET<IWordList, Pagination>('/word', {
        page: 0,
        pageSize: 1
      })
      setTotal(data.total)
    } catch (e) {
    } finally {
      setLoading(false)
    }
  }

  const goToItemPage = (page: number) => {
    navigation.navigate('Detail', { page })
  }

  useEffect(() => {
    fetchData()
  }, [useIsFocused])

  if (!total) return <Loading fullScreen />

  return (
    <SafeAreaViewWrapper hideHeader>
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={loading} onRefresh={fetchData} />
        }
      >
        {[...Array(Math.ceil(total / 50)).keys()]?.map((item) => (
          <Button
            onPress={() => goToItemPage(item)}
            key={item}
            color="blue"
            wrapperClassNames="my-2"
          >
            Word List {item + 1}
          </Button>
        ))}
      </ScrollView>
    </SafeAreaViewWrapper>
  )
}

export default WordList
