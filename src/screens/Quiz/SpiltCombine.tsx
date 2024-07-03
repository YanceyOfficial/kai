import { produce } from 'immer'
import { FC, useState } from 'react'
import { View } from 'react-native'
import { shuffle } from 'yancey-js-util'
import AudioPlayer from '../../components/AudioPlayer'
import Button from '../../components/Button'
import { Quiz } from '../../shared/types'

interface Props {
  quiz: Quiz
}

const SplitCombine: FC<Props> = ({ quiz }) => {
  const [combines, setCombines] = useState<string[]>(
    new Array(quiz.choices.length).fill('')
  )
  const choices = shuffle(quiz.choices)

  const addCombine = (syllabification: string) => {
    const emptyIndex = combines.findIndex((combine) => combine === '')
    if (emptyIndex > -1) {
      const newCombine = produce(combines, (draft) => {
        draft[emptyIndex] = syllabification
      })
      setCombines(newCombine)
    }
  }

  const subtractCombine = (idx: number) => {
    const newCombine = produce(combines, (draft) => {
      draft[idx] = ''
    })

    setCombines(newCombine)
  }

  return (
    <View className="flex-1 justify-center items-center gap-12">
      <AudioPlayer word={quiz.question} />

      <View className="flex-row">
        {combines.map((combine, i) => (
          <>
            {combine === '' ? (
              <View key={i} className="w-8 h-1 bg-[#e5e5e5] mr-2" />
            ) : (
              <Button
                key={i}
                color="white"
                variant="outlined"
                wrapperClassNames="mr-2 last:mr-0"
                onPress={() => subtractCombine(i)}
              >
                {combine}
              </Button>
            )}
          </>
        ))}
      </View>

      <View className="flex-row visible">
        {choices.map((item, i) => {
          const isCombined = combines.includes(item)
          return (
            <Button
              key={i}
              color="white"
              variant="outlined"
              wrapperClassNames="mr-2 last:mr-0"
              disabled={isCombined}
              onPress={() => addCombine(item)}
              textClassNames={isCombined ? 'opacity-0' : ''}
            >
              {item}
            </Button>
          )
        })}
      </View>
    </View>
  )
}

export default SplitCombine
