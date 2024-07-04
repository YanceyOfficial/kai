import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import classNames from 'classnames'
import Button from 'components/Button'
import FlipWordCard from 'components/FlipWordCard'
import CloseIcon from 'components/Icon/CloseIcon'
import Loading from 'components/Loading'
import ProgressBar from 'components/ProgressBar'
import { useAtomValue } from 'jotai'
import { FC, useEffect, useMemo, useState } from 'react'
import { Pressable, View } from 'react-native'
import { AnimatableValue, useSharedValue } from 'react-native-reanimated'
import { GET, POST } from 'shared/axios'
import { isPlayingAtom } from 'stores/global'
import {
  RootStackParamList,
  WeightageAction,
  WeightageDto,
  Word,
  WordList
} from 'types'
import { shuffle } from 'yancey-js-util'

type Props = NativeStackScreenProps<RootStackParamList, 'Detail'>

const WordItemScreen: FC<Props> = ({ navigation, route }) => {
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

  // const handleMark = async () => {
  //   if (!dataSource) return

  //   setDataSource(
  //     produce(dataSource, (draft) => {
  //       draft.words[idx].isMarked = !draft.words[idx].isMarked
  //     })
  //   )

  //   await POST<unknown, MarkDto>(
  //     `/word/mark/${route.params.id}/${wordInfo?._id}`,
  //     {
  //       isMarked: !wordInfo?.isMarked
  //     }
  //   )
  // }

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

  const backToWordListPage = () => {
    navigation.goBack()
  }

  useEffect(() => {
    fetchData()
  }, [isFocused, route.params.id])

  useEffect(() => {
    navigation.getParent()?.setOptions({
      tabBarStyle: {
        display: 'none'
      }
    })
    return () =>
      navigation.getParent()?.setOptions({
        tabBarStyle: undefined
      })
  }, [navigation])

  if (loading || !wordInfo) return <Loading fullScreen />

  return (
    <View className="px-4 py-8 flex-1 flex justify-between">
      <View className="flex flex-row items-center">
        <Pressable onPress={backToWordListPage}>
          <CloseIcon />
        </Pressable>
        <ProgressBar progress={progress} wrapperClassNames="ml-4" />
        {/* <LikeButton onPress={handleMark} /> */}
      </View>

      <View className="flex items-center">
        <FlipWordCard
          wordInfo={wordInfo}
          isFlipped={isFlipped}
          onPress={handleFlip}
        />
      </View>

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
    </View>
  )
}

export default WordItemScreen
