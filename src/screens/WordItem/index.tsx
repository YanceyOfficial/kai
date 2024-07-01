import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import { FC, useEffect, useMemo, useState } from 'react'
import { Pressable, View } from 'react-native'
import { AnimatableValue, useSharedValue } from 'react-native-reanimated'
import { shuffle } from 'yancey-js-util'
import Button from '../../components/Button'
import FlipWordCard from '../../components/FlipWordCard'
import CloseIcon from '../../components/Icon/CloseIcon'
import LikeButton from '../../components/LikeButton'
import Loading from '../../components/Loading'
import ProgressBar from '../../components/ProgressBar'
import { GET } from '../../shared/axios'
import { RootStackParamList, Word, WordList } from '../../shared/types'

type Props = NativeStackScreenProps<RootStackParamList, 'Detail'>

const WordItemScreen: FC<Props> = ({ navigation, route }) => {
  const isFocused = useIsFocused()
  const [loading, setLoading] = useState(false)
  const [idx, setIdx] = useState(0)
  const [dataSource, setDataSource] = useState<WordList | null>(null)
  const isFlipped = useSharedValue(true)
  const progress = useMemo(
    () =>
      `${((idx + 1) / (dataSource?.words.length || 1)) * 100}%` as AnimatableValue,
    [idx, dataSource]
  )
  const currWord = useMemo(() => dataSource?.words?.[idx], [dataSource, idx])

  const handleFlip = () => {
    isFlipped.value = !isFlipped.value
  }

  const toNextWord = () => {
    if (!dataSource) return

    if (idx < dataSource?.words?.length - 1) {
      setIdx(idx + 1)
    } else {
      navigation.navigate('Quiz', { id: route.params.id })
    }
  }

  const switchWord = () => {
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
    setIdx(0)
    fetchData()
  }, [isFocused, route.params.id])

  if (loading || !currWord) return <Loading />

  return (
    <View className="px-4 py-8 flex-1 flex justify-between">
      <View className="flex flex-row items-center">
        <Pressable onPress={backToWordListPage}>
          <CloseIcon />
        </Pressable>
        <ProgressBar progress={progress} />
        <LikeButton />
      </View>

      <View className="flex items-center">
        <FlipWordCard
          wordInfo={currWord}
          isFlipped={isFlipped}
          onPress={handleFlip}
        />
      </View>

      <Button onPress={switchWord}>Next</Button>
    </View>
  )
}

export default WordItemScreen
