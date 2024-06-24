import { NativeStackScreenProps } from '@react-navigation/native-stack'
import { FC, useEffect, useMemo, useState } from 'react'
import { DimensionValue, Pressable, View } from 'react-native'
import AudioPlayer from '../../components/Audio'
import Button from '../../components/Button'
import FlipWordCard from '../../components/FlipWordCard'
import CloseIcon from '../../components/Icon/CloseIcon'
import ProgressBar from '../../components/ProgressBar'
import { GET } from '../../shared/axios'
import { RootStackParamList, WordList } from '../../shared/types'

type Props = NativeStackScreenProps<RootStackParamList, 'Detail'>

const WordItemScreen: FC<Props> = ({ navigation, route }) => {
  const [idx, setIdx] = useState(0)
  const [dataSource, setDataSource] = useState<WordList | null>(null)
  const progress: DimensionValue = `${((idx + 1) / (dataSource?.words.length || 1)) * 100}%`
  const currWord = useMemo(() => dataSource?.words?.[idx], [dataSource, idx])

  const fetchData = async () => {
    try {
      const { data } = await GET<WordList>(`/word/${route.params.id}`)
      setDataSource(data)
    } catch {}
  }

  const backToWordListPage = () => {
    navigation.goBack()
  }

  useEffect(() => {
    fetchData()
  }, [])

  if (!currWord) return null

  return (
    <View className="px-4 py-8 flex-1 flex justify-between">
      <View className="flex flex-row items-center">
        <Pressable onPress={backToWordListPage}>
          <CloseIcon />
        </Pressable>
        <ProgressBar progress={progress} />
      </View>

      <View className="flex items-center">
        <AudioPlayer word={currWord.word} />
        <FlipWordCard wordInfo={currWord} />
      </View>

      <Button
        onPress={() => {
          setIdx(idx + 1)
        }}
      >
        Next
      </Button>
    </View>
  )
}

export default WordItemScreen
