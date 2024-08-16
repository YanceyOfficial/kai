import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import classNames from 'classnames'
import { useAtomValue } from 'jotai'
import { FC, useEffect, useMemo, useState } from 'react'
import { View } from 'react-native'
import { AnimatableValue, useSharedValue } from 'react-native-reanimated'
import Button from 'src/components/Button'
import FlipWordCard from 'src/components/FlipWordCard'
import Loading from 'src/components/Loading'
import ProgressBar from 'src/components/ProgressBar'
import SafeAreaViewWrapper from 'src/components/SafeAreaViewWrapper'
import useHideBottomTab from 'src/hooks/useHideBottomTab'
import { GET, POST } from 'src/shared/axios'
import { isPlayingAtom } from 'src/stores/global'
import {
  FactorAction,
  StatusDto,
  Pagination,
  RootStackParamList,
  Word,
  WordList
} from 'src/types'

type Props = NativeStackScreenProps<RootStackParamList, 'Detail'>

const WordItemScreen: FC<Props> = ({ navigation, route }) => {
  useHideBottomTab(navigation)
  const isPlaying = useAtomValue(isPlayingAtom)
  const isFocused = useIsFocused()
  const [loading, setLoading] = useState(false)
  const [idx, setIdx] = useState(0)
  const [words, setWords] = useState<Word[] | null>(null)
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

    if (!isRemembered) {
      POST<unknown, StatusDto>(`/word/setStatus/${wordInfo?._id}`, {
        action: isRemembered ? FactorAction.Subtraction : FactorAction.Addition
      })
    }
  }

  const switchToNextWord = async () => {
    isFlipped.value = true
    setShowContinueBtn(false)
    setTimeout(() => {
      if (!words) return

      if (idx < words.length - 1) {
        setIdx(idx + 1)
      } else {
        navigation.replace('Quiz', { page: route.params.page })
      }
    }, 250)
  }

  const fetchData = async () => {
    setLoading(true)
    try {
      const { data } = await GET<WordList, Pagination>('/word', {
        page: route.params.page,
        pageSize: 50
      })
      setWords(data.items)
    } catch (e) {
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [isFocused, route.params.page])

  if (loading || !wordInfo) return <Loading fullScreen />

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
            wrapperClassNames={classNames('flex-1 ml-0')}
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
              wrapperClassNames={classNames('flex-1 ml-2')}
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
