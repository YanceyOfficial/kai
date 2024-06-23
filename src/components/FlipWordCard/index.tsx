import { FC, useEffect } from 'react'
import { Pressable, Text } from 'react-native'
import { useSharedValue } from 'react-native-reanimated'
import { Word } from '../../shared/types'
import Card from '../Card'
import FlipCard from '../FlipCard'

interface Props {
  wordInfo: Word
}

const FlipWordCard: FC<Props> = ({ wordInfo }) => {
  const isFlipped = useSharedValue(false)

  const handlePress = () => {
    isFlipped.value = !isFlipped.value
  }

  useEffect(() => {
    isFlipped.value = false
  }, [wordInfo])

  return (
    <Pressable className="relative mt-4" onPress={handlePress}>
      <FlipCard
        isFlipped={isFlipped}
        cardStyle="w-full"
        FlippedContent={
          <Card wrapperClassNames="w-full h-[500px]">
            <Text className="text-lg font-bold">{wordInfo.explanation}</Text>
          </Card>
        }
        RegularContent={
          <Card wrapperClassNames="w-full h-[500px]">
            <Text
              className="text-lg"
              style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
            >
              {wordInfo.word}
            </Text>
          </Card>
        }
      />
    </Pressable>
  )
}

export default FlipWordCard
