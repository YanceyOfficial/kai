import { FC } from 'react'
import { Dimensions, Pressable, Text, View } from 'react-native'
import { SharedValue } from 'react-native-reanimated'
import RenderHtml from 'react-native-render-html'
import { Word } from '../../shared/types'
import AudioPlayer from '../AudioPlayer'
import Card from '../Card'
import FlipCard from '../FlipCard'

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
          <Card wrapperClassNames="w-full h-96">
            <View className="gap-4">
              <Text className="text-lg font-bold">{wordInfo.word}</Text>
              <Text className="text-lg font-bold">{wordInfo.explanation}</Text>
              <Text className="text-xl">{wordInfo.phoneticNotation}</Text>
              {wordInfo.examples.map((example) => (
                <View>
                  <RenderHtml
                    source={{ html: example }}
                    contentWidth={Dimensions.get('window').width}
                    key={example}
                  />
                </View>
              ))}
            </View>
          </Card>
        }
        FlippedContent={
          <Card wrapperClassNames="w-full h-96 justify-center items-center">
            <Text
              className="text-4xl text-center mb-8"
              style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
            >
              {wordInfo.word}
            </Text>
            <AudioPlayer word={wordInfo.word} />
          </Card>
        }
      />
    </Pressable>
  )
}

export default FlipWordCard
