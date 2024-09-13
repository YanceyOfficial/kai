import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import { FC, useEffect, useState } from 'react'
import { RefreshControl, ScrollView } from 'react-native'
import Button from 'src/components/Button'
import Loading from 'src/components/Loading'
import SafeAreaViewWrapper from 'src/components/SafeAreaViewWrapper'
import { GET } from 'src/shared/axios'
import { DEFAULT_PAGE_SIZE } from 'src/shared/constants'
import { RootStackParamList, Statistics } from 'src/types'

type Props = NativeStackScreenProps<RootStackParamList, 'WordList'>

const WordList: FC<Props> = ({ navigation }) => {
  const [statistics, setStatistics] = useState<Statistics | null>(null)
  const [loading, setLoading] = useState(false)
  const fetchStatistics = async () => {
    setLoading(true)
    try {
      const { data } = await GET<Statistics, { pageSize: number }>(
        '/word/statistics',
        { pageSize: DEFAULT_PAGE_SIZE }
      )
      setStatistics(data)
    } catch (e) {
    } finally {
      setLoading(false)
    }
  }

  const goToItemPage = (page: number, fromChallenging: boolean) => {
    navigation.navigate('Detail', { page, fromChallenging })
  }

  useEffect(() => {
    fetchStatistics()
  }, [useIsFocused])

  if (loading) return <Loading fullScreen />

  return (
    <SafeAreaViewWrapper hideHeader>
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={loading} onRefresh={fetchStatistics} />
        }
      >
        <Button
          onPress={() => goToItemPage(-1, true)}
          color="green"
          wrapperClassNames="mb-2"
          disabled={statistics?.challengingCount === 0}
        >
          {`Challenging: ${statistics?.challengingCount}`}
        </Button>

        {statistics?.items.map((item) => (
          <Button
            key={item.page}
            onPress={() => goToItemPage(item.page, false)}
            color="blue"
            wrapperClassNames="my-2"
          >
            {`Word List ${item.page + 1} - ${item.learnedCount}/${item.total}`}
          </Button>
        ))}
      </ScrollView>
    </SafeAreaViewWrapper>
  )
}

export default WordList
