import { AudioPlayer } from '@/components/audio-player'
import FlipCard from '@/components/flip-card'
import { WordCard } from '@/components/word-card'
import { DEFAULT_CHALLENGING_FACTOR } from '@/shared/constants'
import { Word } from '@/shared/types'
import { cn } from '@/shared/utils'
import React, { FC, memo, useMemo } from 'react'
import { Dimensions, Pressable, Text, View, useColorScheme } from 'react-native'
import { SharedValue } from 'react-native-reanimated'

interface Props {
  wordInfo: Word
  isFlipped: SharedValue<boolean>
  onPress: () => void
}

const FlipWordCard: FC<Props> = ({ wordInfo, isFlipped, onPress }) => {
  const isDarkMode = useColorScheme() === 'dark'
  const cardHeight = useMemo(() => Dimensions.get('window').height * 0.6, [])

  const renderRegular = useMemo(
    () => (
      <WordCard
        wrapperClassNames="w-11/12"
        wrapperStyles={{ height: cardHeight }}
      >
        <View className="gap-4">
          <Text
            className={cn('text-lg font-bold', {
              'text-[#f1f7fb]': isDarkMode
            })}
          >
            {wordInfo.name}
          </Text>
          <Text
            className={cn('text-lg font-bold', {
              'text-[#f1f7fb]': isDarkMode
            })}
          >
            {wordInfo.explanation}
          </Text>
          {wordInfo.phoneticNotation.split(' ').length <= 1 && (
            <Text
              className={cn('text-xl', {
                'text-[#f1f7fb]': isDarkMode
              })}
            >
              {wordInfo.phoneticNotation}
            </Text>
          )}
          {wordInfo.examples.map((example) => (
            <Text
              className={cn('text-sm text-[#4b4b4b]', {
                'text-[#f1f7fb]': isDarkMode
              })}
              key={example}
              selectable
            >
              {example}
            </Text>
          ))}
        </View>
      </WordCard>
    ),
    [wordInfo, isDarkMode, cardHeight]
  )

  const renderFlipped = useMemo(
    () => (
      <WordCard
        wrapperClassNames="w-11/12 justify-center items-center relative"
        wrapperStyles={{ height: cardHeight }}
      >
        <View className="absolute left-2 top-4 flex flex-row items-center">
          <Text
            style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
            className="ml-2 text-[#C386F8]"
          >
            {!wordInfo.isLearned
              ? 'NEW WORD'
              : wordInfo.factor > DEFAULT_CHALLENGING_FACTOR
                ? 'CHALLENGING WORD'
                : ''}
          </Text>
        </View>
        <Text
          className={cn('mb-8 text-center text-4xl', {
            'text-[#f1f7fb]': isDarkMode
          })}
          style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
        >
          {wordInfo.name}
        </Text>
        <AudioPlayer word={wordInfo.name} />
      </WordCard>
    ),
    [wordInfo, isDarkMode, cardHeight]
  )

  return (
    <Pressable className="relative mt-4 w-full" onPress={onPress}>
      <FlipCard
        isFlipped={isFlipped}
        cardStyle="w-full items-center justify-center"
        RegularContent={renderRegular}
        FlippedContent={renderFlipped}
      />
    </Pressable>
  )
}

export default memo(FlipWordCard)
