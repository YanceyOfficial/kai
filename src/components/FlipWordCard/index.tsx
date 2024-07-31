import classNames from 'classnames'
import { FC } from 'react'
import { Dimensions, Pressable, Text, View, useColorScheme } from 'react-native'
import { SharedValue } from 'react-native-reanimated'
import Card from 'src/components/Card'
import FlipCard from 'src/components/FlipCard'
import WordAudioPlayer from 'src/components/WordAudioPlayer'
import { Word } from 'src/types'

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
        cardStyle="w-full items-center"
        RegularContent={
          <Card
            wrapperClassNames="w-11/12"
            wrapperStyles={{ height: Dimensions.get('window').height * 0.6 }}
          >
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
                  selectable
                >
                  {example}
                </Text>
              ))}
            </View>
          </Card>
        }
        FlippedContent={
          <Card
            wrapperClassNames="w-11/12 justify-center items-center"
            wrapperStyles={{ height: Dimensions.get('window').height * 0.6 }}
          >
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
