import { FC, useEffect, useMemo, useState } from 'react'
import { Pressable, View } from 'react-native'
import Button from '../../components/Button'
import FlipWordCard from '../../components/FlipWordCard'
import CloseIcon from '../../components/Icon/CloseIcon'
import { GET } from '../../shared/axios'
import { WordList } from '../../shared/types'

interface Props {
  navigation: any
  route: any
}

const WordItemScreen: FC<Props> = ({ navigation, route }) => {
  const [idx, setIdx] = useState(0)
  const [dataSource, setDataSource] = useState<WordList | null>(null)
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
    <View className="p-4 flex-1 flex justify-between">
      <View className="flex flex-row items-center">
        <Pressable onPress={backToWordListPage}>
          <CloseIcon />
        </Pressable>

        <View className="flex-1 bg-[#E5E5E5] rounded-3xl h-5 ml-4">
          <View className="bg-[#77C93C] w-[76px] h-5 rounded-3xl relative">
            <View className="bg-[#91D352] w-[56px] h-2 rounded absolute top-1 left-[10px]" />
          </View>
        </View>
      </View>
      <FlipWordCard wordInfo={currWord} />

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
