/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React from 'react'
import type { PropsWithChildren } from 'react'
import {
  Pressable,
  SafeAreaView,
  StyleSheet,
  Text,
  useColorScheme,
  View
} from 'react-native'
import { Colors } from 'react-native/Libraries/NewAppScreen'
import Button from './components/Button'
import Card from './components/Card'
import { useSharedValue } from 'react-native-reanimated'
import FlipCard from './components/FlipCard'
import Sound from 'react-native-sound'

type SectionProps = PropsWithChildren<{
  title: string
}>

function App(): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark'
  const isFlipped = useSharedValue(false)

  const handlePress = () => {
    isFlipped.value = !isFlipped.value
  }

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter
  }

  const handleAudio = async () => {
    Sound.setCategory('Playback')
    const whoosh = new Sound(
      'https://dict.youdao.com/dictvoice?type=0&audio=adversity',
      null,
      (error) => {
        if (error) {
          console.log('failed to load the sound', error)
          return
        }
        // loaded successfully
        console.log(
          'duration in seconds: ' +
            whoosh.getDuration() +
            'number of channels: ' +
            whoosh.getNumberOfChannels()
        )

        // Play the sound with an onEnd callback
        whoosh.play((success) => {
          if (success) {
            console.log('successfully finished playing')
          } else {
            console.log('playback failed due to audio decoding errors')
          }
        })
      }
    )
  }

  return (
    <SafeAreaView style={backgroundStyle} className="flex-1">
      <View style={styles.sectionContainer}>
        <Button color="green">Start</Button>
        <Button color="white" wrapperClassNames="my-4" onPress={handleAudio}>
          Audio Play
        </Button>
        <Button color="blue" onPress={handlePress}>
          Flip Card
        </Button>

        <Pressable className="relative mt-4" onPress={handlePress}>
          <FlipCard
            isFlipped={isFlipped}
            cardStyle="w-full"
            FlippedContent={
              <Card wrapperClassNames="w-full h-[500px]">
                <Text className="text-lg font-bold">
                  n. 逆境, 不幸, 灾祸, 灾难
                </Text>
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
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24
  }
})

export default App
