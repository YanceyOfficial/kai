import { FC, useEffect, useState } from 'react'
import { Text, View } from 'react-native'
import { useIsFocused } from '@react-navigation/native';
import { GET } from '../../shared/axios'
import { WordList as IWordList } from '../../shared/types'
import Button from '../../components/Button'

interface Props {
  navigation: any
}

const WordList: FC<Props> = ({ navigation }) => {
  const isFocused = useIsFocused();
  const [dataSource, setDataSource] = useState<IWordList[] | null>(null)
  const fetchData = async () => {
    try {
      const { data } = await GET<IWordList[]>('/word')
      setDataSource(data)
    } catch {
      navigation.navigate('Login')
    }
  }

  const goToItemPage = (id: string) => {
    navigation.navigate('Detail', { id })
  }

  useEffect(() => {
    fetchData()
  }, [isFocused])
  return (
    <View className="p-4">
      <Text>Hello</Text>
      {dataSource?.map((item) => (
        <Button
          onPress={() => goToItemPage(item._id)}
          key={item._id}
          wrapperClassNames="mt-4"
        >
          {item.title}
        </Button>
      ))}
    </View>
  )
}

export default WordList
