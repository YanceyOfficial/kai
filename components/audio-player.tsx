import Button from '@/components/button'
import { youdaoWordAudioUrl } from '@/shared/utils'
import { useAudioPlayer } from 'expo-audio'
import LottieView from 'lottie-react-native'
import { useEffect, useRef } from 'react'

export function AudioPlayer({ word }: { word: string }) {
  const animationRef = useRef<LottieView>(null)
  const player = useAudioPlayer(youdaoWordAudioUrl(word))

  useEffect(() => {
    player.play()
    animationRef.current?.play()
  }, [player])

  useEffect(() => {
    if (!player.paused) {
      animationRef.current?.reset()
    }
  }, [player.paused])

  return (
    <Button
      color="blue"
      wrapperClassNames="p-2"
      onPress={() => {
        player.seekTo(0)
        player.play()
        animationRef.current?.play()
      }}
    >
      <LottieView
        ref={animationRef}
        source={require('@/assets/lotties/lottie-sound.json')}
        style={[{ width: 48, height: 48 }]}
        loop
        progress={1}
        autoPlay={false}
      />
    </Button>
  )
}
