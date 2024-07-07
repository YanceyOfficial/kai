import { useSetAtom } from 'jotai'
import Sound from 'react-native-sound'
import { isPlayingAtom } from 'src/stores/global'

interface Options {
  onStartPlayhandler: () => void
  onStopPlayhandler: () => void
}

const useAudioPlayer = (options?: Options) => {
  const setIsPlaying = useSetAtom(isPlayingAtom)

  const handleAudioFromLocalFile = async (audioSource: string) => {
    setIsPlaying(true)
    if (typeof options?.onStartPlayhandler === 'function') {
      options.onStartPlayhandler()
    }

    Sound.setCategory('Playback')

    const whoosh = new Sound(audioSource, () => {
      // Play the sound with an onEnd callback
      whoosh.play((success) => {
        if (success) {
          console.log('successfully finished playing')
        } else {
          console.log('playback failed due to audio decoding errors')
        }

        setIsPlaying(false)
        if (typeof options?.onStopPlayhandler === 'function') {
          options.onStopPlayhandler()
        }
      })
    })
  }

  const handleAudioFromNetworkFile = async (audioSource: string) => {
    console.log(audioSource)

    setIsPlaying(true)
    if (typeof options?.onStartPlayhandler === 'function') {
      options.onStartPlayhandler()
    }

    Sound.setCategory('Playback')

    const whoosh = new Sound(audioSource, undefined, () => {
      // Play the sound with an onEnd callback
      whoosh.play((success) => {
        if (success) {
          console.log('successfully finished playing')
        } else {
          console.log('playback failed due to audio decoding errors')
        }

        setIsPlaying(false)
        if (typeof options?.onStopPlayhandler === 'function') {
          options.onStopPlayhandler()
        }
      })
    })
  }

  return { handleAudioFromLocalFile, handleAudioFromNetworkFile }
}

export default useAudioPlayer
