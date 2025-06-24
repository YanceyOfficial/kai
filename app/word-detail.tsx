import Button from '@/components/button'
import FlipWordCard from '@/components/flip-word-card'
import Loading from '@/components/full-text-loading'
import ProgressBar from '@/components/progress-bar'
import SafeAreaViewWrapper from '@/components/safe-area-view-wrapper'
import { DEFAULT_PAGE_SIZE } from '@/shared/constants'
import { fetcher } from '@/shared/fetcher'
import { FactorAction, WordList, WordType } from '@/shared/types'
import { cn } from '@/shared/utils'
import { isPlayingAtom } from '@/stores/global'
import { useLocalSearchParams, useRouter } from 'expo-router'
import { useAtomValue } from 'jotai'
import { FC, useMemo, useState } from 'react'
import { View } from 'react-native'
import { AnimatableValue, useSharedValue } from 'react-native-reanimated'
import useSWR from 'swr'
import { shuffle } from 'yancey-js-util'

const WordItemScreen: FC = () => {
  const router = useRouter()
  const params = useLocalSearchParams()
  const { isLoading, data } = useSWR<WordList>(
    (params.wordType as unknown as WordType) === WordType.Challenging
      ? '/word/challenging'
      : `/word?page=${params.page}&pageSize=${DEFAULT_PAGE_SIZE}`
  )
  const words = useMemo(() => {
    if (!data) return []
    return shuffle(data.items).sort((a, b) => {
      if (a.isLearned === b.isLearned) {
        return b.factor - a.factor
      } else {
        return Number(a.isLearned) - Number(b.isLearned)
      }
    })
  }, [data])
  const isPlaying = useAtomValue(isPlayingAtom)
  const [idx, setIdx] = useState(0)
  const isFlipped = useSharedValue(true)
  const [showContinueBtn, setShowContinueBtn] = useState(false)
  const wordInfo = useMemo(() => words?.[idx], [words, idx])
  const progress = useMemo(
    () => `${((idx + 1) / (words?.length || 1)) * 100}%` as AnimatableValue,
    [idx, words]
  )

  const showExplanation = async (isRemembered: boolean) => {
    if (!isFlipped.value) {
      return
    }

    isFlipped.value = false
    setShowContinueBtn(true)

    fetcher(`/word/status/${wordInfo?._id}`, {
      method: 'POST',
      body: {
        action: isRemembered ? FactorAction.Subtraction : FactorAction.Addition
      }
    })
  }

  const switchToNextWord = async () => {
    isFlipped.value = true
    setShowContinueBtn(false)
    setTimeout(() => {
      if (!words) return

      if (idx < words.length - 1) {
        setIdx(idx + 1)
      } else {
        if ((params.wordType as unknown as WordType) === WordType.Challenging) {
          router.replace('/(tabs)')
        } else {
          router.replace({ pathname: '/quiz', params: { page: params.page } })
        }
      }
    }, 250)
  }

  if (isLoading || !wordInfo) return <Loading fullScreen />

  return (
    <SafeAreaViewWrapper
      headerRightComp={
        <ProgressBar progress={progress} wrapperClassNames="ml-4" />
      }
    >
      <FlipWordCard
        wordInfo={wordInfo}
        isFlipped={isFlipped}
        onPress={() => showExplanation(false)}
      />
      <View className="flex-row">
        {showContinueBtn ? (
          <Button
            onPress={switchToNextWord}
            disabled={isPlaying}
            color="green"
            wrapperClassNames={cn('flex-1 ml-0')}
          >
            CONTINUE
          </Button>
        ) : (
          <>
            <Button
              onPress={() => showExplanation(false)}
              disabled={isPlaying}
              color="white"
              variant="outlined"
              wrapperClassNames="flex-1 mr-2"
            >
              FORGOT
            </Button>
            <Button
              onPress={() => showExplanation(true)}
              disabled={isPlaying}
              color="white"
              variant="outlined"
              wrapperClassNames={cn('flex-1 ml-2')}
            >
              REMEMBER
            </Button>
          </>
        )}
      </View>
    </SafeAreaViewWrapper>
  )
}

export default WordItemScreen
