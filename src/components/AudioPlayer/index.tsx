import { FC, useEffect } from 'react'
import { TouchableOpacity } from 'react-native'
import Sound from 'react-native-sound'
import { YOUDAO_VOICE_URL } from '../../shared/constants'
import AudioPlayingIcon from '../Icon/AudioPlayingIcon'

interface Props {
  word: string
}

const AudioPlayer: FC<Props> = ({ word }) => {
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

  useEffect(() => {
    handleAudio()
  }, [word])

  return (
    <TouchableOpacity onPress={handleAudio} className="z-10">
      <AudioPlayingIcon width={64} height={64} />
    </TouchableOpacity>
  )
}

export default AudioPlayer
