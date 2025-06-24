import Button from '@/components/button'
import Loading from '@/components/full-text-loading'
import SafeAreaViewWrapper from '@/components/safe-area-view-wrapper'
import { DEFAULT_PAGE_SIZE } from '@/shared/constants'
import { Statistics, WordType } from '@/shared/types'
import { useRouter } from 'expo-router'
import { RefreshControl, ScrollView } from 'react-native'
import useSWR from 'swr'

export default function WordList() {
  const router = useRouter()
  const {
    data: statistics,
    isLoading,
    mutate
  } = useSWR<Statistics>(`/word/statistics?pageSize=${DEFAULT_PAGE_SIZE}`)

  const goToItemPage = (page: number, wordType: WordType) => {
    router.push({ pathname: '/word-detail', params: { page, wordType } })
  }

  if (isLoading) return <Loading fullScreen />

  return (
    <SafeAreaViewWrapper hideHeader>
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={isLoading} onRefresh={mutate} />
        }
      >
        <Button
          onPress={() => goToItemPage(-1, WordType.Challenging)}
          color="green"
          wrapperClassNames="mb-2"
          disabled={statistics?.challengingCount === 0}
        >
          {`Challenging: ${statistics?.challengingCount}`}
        </Button>

        {statistics?.items.map((item) => (
          <Button
            key={item.page}
            onPress={() => goToItemPage(item.page, WordType.Normal)}
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
