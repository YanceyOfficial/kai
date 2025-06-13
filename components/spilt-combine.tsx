import { AudioPlayer } from '@/components/audio-player'
import Button from '@/components/button'
import { Quiz } from '@/shared/types'
import { cn } from '@/shared/utils'
import { answerInfoAtom } from '@/stores/quiz'
import { produce } from 'immer'
import { useAtom } from 'jotai'
import { FC, Fragment, useEffect, useState } from 'react'
import { View, useColorScheme } from 'react-native'

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
  }, [answerInfo, combines, setAnswerInfo])

  useEffect(() => {
    setCombines(new Array(quiz.choices.length).fill(''))
  }, [quiz])

  return (
    <View className="flex-1 items-center justify-center">
      <AudioPlayer word={quiz.question} />

      <View className="mt-8 h-14 flex-row items-end">
        {combines.map((combine, i) => (
          <Fragment key={i}>
            {combine === '' ? (
              <View
                className={cn(
                  'mr-2 h-1 w-8',
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
                wrapperClassNames={cn('mr-2', {
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

      <View className="item-center visible mt-8 flex-row justify-center">
        {quiz.choices.map((choice, i) => {
          const isCombined = combines.includes(choice)
          return (
            <Button
              key={i}
              color="white"
              variant="outlined"
              wrapperClassNames={cn('mr-2 last:mr-0', {
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
