import { FC, useEffect, useState } from 'react'
import { Text, View } from 'react-native'
import { GET } from '../../shared/axios'
import { WordList as IWordList } from '../../shared/types'
import Button from '../../components/Button'
import FlipWordCard from '../../components/FlipWordCard'

interface Props {
  navigation: any
}

const WordList: FC<Props> = ({  navigation }) => {
  const [dataSource, setDataSource] = useState<IWordList[] | null>(null)
  const fetchData = async () => {
    try {
      const { data } = await GET<IWordList[]>(`/word/${id}`)
      setDataSource(data)
    } catch {
      navigation.navigate('Login')
    }
  }

  const goToItemPage = (id: string) => {}

  useEffect(() => {
    // fetchData()
  }, [])
  return (
    <View className="p-4 flex-1 flex justify-between">
      <FlipWordCard />

      <View className='flex flex-row justify-between'>
        <Button color='blue' wrapperClassNames='w-[48%]'>Prev</Button>
        <Button wrapperClassNames='w-[48%]'>Next</Button>
      </View>
    </View>
  )
}

export default WordList
