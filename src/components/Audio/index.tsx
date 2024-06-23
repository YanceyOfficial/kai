import { FC } from 'react'
import Sound from 'react-native-sound'
import { YOUDAO_VOICE_URL } from '../../shared/constants'
import Button from '../Button'

interface Props {
  word: string
}

const Audio: FC<Props> = ({ word }) => {
  const handleAudio = async () => {
    Sound.setCategory('Playback')
    const whoosh = new Sound(
      `${YOUDAO_VOICE_URL}${word}`,
      // @ts-ignore
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
    <Button color="white" wrapperClassNames="my-4" onPress={handleAudio}>
      Audio Play
    </Button>
  )
}

export default Audio
