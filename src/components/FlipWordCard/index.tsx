import { FC } from 'react'
import { Pressable, Text, View } from 'react-native'
import { SharedValue } from 'react-native-reanimated'
import { Word } from '../../shared/types'
import Card from '../Card'
import FlipCard from '../FlipCard'
import AudioPlayer from '../AudioPlayer'

interface Props {
  wordInfo: Word
  isFlipped: SharedValue<boolean>
  onPress: () => void
}

const FlipWordCard: FC<Props> = ({ wordInfo, isFlipped, onPress }) => {
  return (
    <Pressable className="relative mt-4 w-full" onPress={onPress}>
      <FlipCard
        isFlipped={isFlipped}
        cardStyle="w-full"
        RegularContent={
          <Card wrapperClassNames="w-full h-96 justify-center items-center">
            <Text
              className="text-4xl text-center"
              style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
            >
              {wordInfo.word}
            </Text>
            <AudioPlayer word={wordInfo.word} />
          </Card>
        }
        FlippedContent={
          <Card wrapperClassNames="w-full h-96">
            <View className="gap-4">
              <Text className="text-lg font-bold">{wordInfo.word}</Text>
              <Text className="text-lg font-bold">{wordInfo.explanation}</Text>
              <Text className="text-xl">{wordInfo.phoneticNotation}</Text>
              {wordInfo.examples.map((example) => (
                <Text className="text-base text-[#4b4b4b]" key={example}>
                  {example}
                </Text>
              ))}
            </View>
          </Card>
        }
      />
    </Pressable>
  )
}

export default FlipWordCard
