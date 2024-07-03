import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import Button from 'components/Button'
import Loading from 'components/Loading'
import { FC, useEffect, useState } from 'react'
import { View } from 'react-native'
import { GET } from 'shared/axios'
import { WordList as IWordList, RootStackParamList } from 'shared/types'

type Props = NativeStackScreenProps<RootStackParamList, 'WordList'>

const WordList: FC<Props> = ({ navigation }) => {
  const isFocused = useIsFocused()
  const [dataSource, setDataSource] = useState<IWordList[] | null>(null)
  const fetchData = async () => {
    try {
      const { data } = await GET<IWordList[]>('/word')
      setDataSource(data)
    } catch (e) {}
  }

  const goToItemPage = (id: string) => {
    navigation.navigate('Detail', { id })
  }

  useEffect(() => {
    fetchData()
  }, [isFocused])

  if (!dataSource) return <Loading fullScreen />

  return (
    <View className="p-4">
      {dataSource?.map((item) => (
        <Button
          onPress={() => goToItemPage(item._id)}
          key={item._id}
          color="blue"
          wrapperClassNames="mt-4"
        >
          {item.title.toUpperCase()}
        </Button>
      ))}
    </View>
  )
}

export default WordList
