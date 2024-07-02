import { useSetAtom } from 'jotai'
import LottieView from 'lottie-react-native'
import { FC, useEffect, useRef } from 'react'
import Sound from 'react-native-sound'
import { YOUDAO_VOICE_URL } from '../../shared/constants'
import { isPlayingAtom } from '../../stores/global'
import Button from '../Button'

interface Props {
  word: string
}

const AudioPlayer: FC<Props> = ({ word }) => {
  const animationRef = useRef<LottieView>(null)
  const setIsPlaying = useSetAtom(isPlayingAtom)

  const handleAudio = async () => {
    animationRef.current?.play()
    setIsPlaying(true)

    Sound.setCategory('Playback')
    const whoosh = new Sound(`${YOUDAO_VOICE_URL}${word}`, undefined, () => {
      whoosh.play((success) => {
        if (success) {
          console.log('successfully finished playing')
        } else {
          console.log('playback failed due to audio decoding errors')
        }
        animationRef.current?.reset()
        setIsPlaying(false)
      })
    })
  }

  useEffect(() => {
    handleAudio()
  }, [word])

  return (
    <Button color="blue" wrapperClassNames="p-2" onPress={handleAudio}>
      <LottieView
        ref={animationRef}
        source={require('../../../assets/lotties/lottie-sound.json')}
        style={[{ width: 48, height: 48 }]}
        loop
        progress={1}
        autoPlay={false}
      />
    </Button>
  )
}

export default AudioPlayer
