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
  RootStackParamList,
  WeightageAction,
  WeightageDto,
  Word,
  WordList
} from 'src/types'
import { shuffle } from 'yancey-js-util'

type Props = NativeStackScreenProps<RootStackParamList, 'Detail'>

const WordItemScreen: FC<Props> = ({ navigation, route }) => {
  useHideBottomTab(navigation)
  const isPlaying = useAtomValue(isPlayingAtom)
  const isFocused = useIsFocused()
  const [loading, setLoading] = useState(false)
  const [idx, setIdx] = useState(0)
  const [dataSource, setDataSource] = useState<WordList | null>(null)
  const isFlipped = useSharedValue(true)
  const [isForgot, setIsForgot] = useState(false)
  const progress = useMemo(
    () =>
      `${((idx + 1) / (dataSource?.words.length || 1)) * 100}%` as AnimatableValue,
    [idx, dataSource]
  )
  const wordInfo = useMemo(() => dataSource?.words?.[idx], [dataSource, idx])

  const handleFlip = () => {
    isFlipped.value = !isFlipped.value
  }

  const toNextWord = () => {
    if (!dataSource) return

    if (idx < dataSource?.words?.length - 1) {
      setIdx(idx + 1)
    } else {
      navigation.replace('Quiz', { id: route.params.id })
    }
  }

  const forgotWord = async () => {
    isFlipped.value = false
    setIsForgot(true)
    await POST<unknown, WeightageDto>(
      `/word/weightage/${route.params.id}/${wordInfo?._id}`,
      {
        action: WeightageAction.Addiation
      }
    )
  }

  const switchToNextWord = async () => {
    if (isForgot) {
      setIsForgot(false)
    } else {
      POST<unknown, WeightageDto>(
        `/word/weightage/${route.params.id}/${wordInfo?._id}`,
        {
          action: WeightageAction.Substract
        }
      )
    }

    if (!isFlipped.value) {
      isFlipped.value = true
      setTimeout(() => {
        toNextWord()
      }, 250)
    } else {
      toNextWord()
    }
  }

  const fetchData = async () => {
    setLoading(true)
    try {
      const { data } = await GET<WordList>(`/word/${route.params.id}`)
      setDataSource({ ...data, words: shuffle<Word>(data.words) })
    } catch {
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [isFocused, route.params.id])

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
        onPress={handleFlip}
      />

      <View className="flex-row">
        {isForgot || (
          <Button
            onPress={forgotWord}
            disabled={isPlaying}
            color="red"
            wrapperClassNames="flex-1 mr-2"
          >
            FORGOT
          </Button>
        )}

        {
          <Button
            onPress={switchToNextWord}
            disabled={isPlaying}
            color="blue"
            wrapperClassNames={classNames('flex-1 ml-2', {
              'ml-0': isForgot
            })}
          >
            {isForgot ? 'NEXT' : 'REMEMBER'}
          </Button>
        }
      </View>
    </SafeAreaViewWrapper>
  )
}

export default WordItemScreen
