import { FC } from 'react'
import { Pressable, Text } from 'react-native'
import { useSharedValue } from 'react-native-reanimated'
import Card from '../Card'
import FlipCard from '../FlipCard'

const FlipWordCard: FC = () => {
  const isFlipped = useSharedValue(false)

  const handlePress = () => {
    isFlipped.value = !isFlipped.value
  }

  return (
    <Pressable className="relative mt-4" onPress={handlePress}>
      <FlipCard
        isFlipped={isFlipped}
        cardStyle="w-full"
        FlippedContent={
          <Card wrapperClassNames="w-full h-[500px]">
            <Text className="text-lg font-bold">n. 逆境, 不幸, 灾祸, 灾难</Text>
          </Card>
        }
        RegularContent={
          <Card wrapperClassNames="w-full h-[500px]">
            <Text
              className="text-lg"
              style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
            >
              adversity
            </Text>
          </Card>
        }
      />
    </Pressable>
  )
}

export default FlipWordCard
