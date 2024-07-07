import LottieView from 'lottie-react-native'
import { FC, useEffect, useRef } from 'react'
import Button from 'src/components/Button'
import useAudioPlayer from 'src/hooks/useAudioPlayer'
import { YOUDAO_VOICE_URL } from 'src/shared/constants'

interface Props {
  word: string
}

const WordAudioPlayer: FC<Props> = ({ word }) => {
  const animationRef = useRef<LottieView>(null)
  const { handleAudioFromNetworkFile } = useAudioPlayer({
    onStartPlayhandler: () => animationRef.current?.play(),
    onStopPlayhandler: () => animationRef.current?.reset()
  })

  useEffect(() => {
    handleAudioFromNetworkFile(`${YOUDAO_VOICE_URL}${word}`)
  }, [word])

  return (
    <Button
      color="blue"
      wrapperClassNames="p-2"
      onPress={() => handleAudioFromNetworkFile(`${YOUDAO_VOICE_URL}${word}`)}
    >
      <LottieView
        ref={animationRef}
        source={require('assets/lotties/lottie-sound.json')}
        style={[{ width: 48, height: 48 }]}
        loop
        progress={1}
        autoPlay={false}
      />
    </Button>
  )
}

export default WordAudioPlayer
