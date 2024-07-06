import classNames from 'classnames'
import { produce } from 'immer'
import { useAtom } from 'jotai'
import { FC, Fragment, useEffect, useState } from 'react'
import { View, useColorScheme } from 'react-native'
import Button from 'src/components/Button'
import WordAudioPlayer from 'src/components/WordAudioPlayer'
import { answerInfoAtom } from 'src/stores/quiz'
import { Quiz } from 'src/types'

interface Props {
  quiz: Quiz
}

const SplitCombine: FC<Props> = ({ quiz }) => {
  const isDarkMode = useColorScheme() === 'dark'
  const [answerInfo, setAnswerInfo] = useAtom(answerInfoAtom)
  const [combines, setCombines] = useState<string[]>(
    new Array(quiz.choices.length).fill('')
  )

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

  useEffect(() => {
    const isDone = combines.every(Boolean)
    if (isDone) {
      setAnswerInfo({ ...answerInfo, answers: combines })
    }
  }, [combines])

  useEffect(() => {
    setCombines(new Array(quiz.choices.length).fill(''))
  }, [quiz])

  return (
    <View className="flex-1 justify-center items-center">
      <WordAudioPlayer word={quiz.question} />

      <View className="flex-row items-end h-14 mt-8">
        {combines.map((combine, i) => (
          <Fragment key={i}>
            {combine === '' ? (
              <View
                className={classNames(
                  'w-8 h-1 mr-2',
                  isDarkMode ? 'bg-[#37464f]' : 'bg-[#e5e5e5]',
                  {
                    'mr-0': i === combines.length - 1
                  }
                )}
              />
            ) : (
              <Button
                color="white"
                variant="outlined"
                wrapperClassNames={classNames('mr-2', {
                  'mr-0': i === combines.length - 1
                })}
                onPress={() => subtractCombine(i)}
              >
                {combine}
              </Button>
            )}
          </Fragment>
        ))}
      </View>

      <View className="flex-row item-center justify-center visible mt-8">
        {quiz.choices.map((choice, i) => {
          const isCombined = combines.includes(choice)
          return (
            <Button
              key={i}
              color="white"
              variant="outlined"
              wrapperClassNames={classNames('mr-2 last:mr-0', {
                'mr-0': i === combines.length - 1
              })}
              disabled={isCombined}
              onPress={() => addCombine(choice)}
              textClassNames={isCombined ? 'opacity-0' : ''}
            >
              {choice}
            </Button>
          )
        })}
      </View>
    </View>
  )
}

export default SplitCombine
