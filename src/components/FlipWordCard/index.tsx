import classNames from 'classnames'
import { FC } from 'react'
import { Pressable, Text, View, useColorScheme } from 'react-native'
import { SharedValue } from 'react-native-reanimated'
import { Word } from 'types'
import Card from '../Card'
import FlipCard from '../FlipCard'
import WordAudioPlayer from '../WordAudioPlayer'

interface Props {
  wordInfo: Word
  isFlipped: SharedValue<boolean>
  onPress: () => void
}

const FlipWordCard: FC<Props> = ({ wordInfo, isFlipped, onPress }) => {
  const isDarkMode = useColorScheme() === 'dark'
  return (
    <Pressable className="relative mt-4 w-full" onPress={onPress}>
      <FlipCard
        isFlipped={isFlipped}
        cardStyle="w-full"
        RegularContent={
          <Card wrapperClassNames="w-full h-96">
            <View className="gap-4">
              <Text
                className={classNames('text-lg font-bold', {
                  'text-[#f1f7fb]': isDarkMode
                })}
              >
                {wordInfo.name}
              </Text>
              <Text
                className={classNames('text-lg font-bold', {
                  'text-[#f1f7fb]': isDarkMode
                })}
              >
                {wordInfo.explanation}
              </Text>
              {wordInfo.phoneticNotation.split(' ').length > 1 || (
                <Text
                  className={classNames('text-xl', {
                    'text-[#f1f7fb]': isDarkMode
                  })}
                >
                  {wordInfo.phoneticNotation}
                </Text>
              )}
              {wordInfo.examples.map((example) => (
                <Text
                  className={classNames('text-sm text-[#4b4b4b]', {
                    'text-[#f1f7fb]': isDarkMode
                  })}
                  key={example}
                >
                  {example}
                </Text>
              ))}
            </View>
          </Card>
        }
        FlippedContent={
          <Card wrapperClassNames="w-full h-96 justify-center items-center">
            <Text
              className={classNames('text-4xl text-center mb-8', {
                'text-[#f1f7fb]': isDarkMode
              })}
              style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
            >
              {wordInfo.name}
            </Text>
            <WordAudioPlayer word={wordInfo.name} />
          </Card>
        }
      />
    </Pressable>
  )
}

export default FlipWordCard
