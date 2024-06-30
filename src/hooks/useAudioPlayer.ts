import Sound from 'react-native-sound'

const useAudioPlayer = () => {
  const handleAudioFromLocalFile = async (audioSource: string) => {
    Sound.setCategory('Playback')

    const whoosh = new Sound(audioSource, () => {
      // Play the sound with an onEnd callback
      whoosh.play((success) => {
        if (success) {
          console.log('successfully finished playing')
        } else {
          console.log('playback failed due to audio decoding errors')
        }
      })
    })
  }

  const handleAudioFromNetworkFile = async (audioSource: string) => {
    Sound.setCategory('Playback')

    const whoosh = new Sound(audioSource, undefined, () => {
      // Play the sound with an onEnd callback
      whoosh.play((success) => {
        if (success) {
          console.log('successfully finished playing')
        } else {
          console.log('playback failed due to audio decoding errors')
        }
      })
    })
  }

  return { handleAudioFromLocalFile, handleAudioFromNetworkFile }
}

export default useAudioPlayer
