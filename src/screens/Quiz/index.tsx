import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import Button from 'components/Button'
import CloseIcon from 'components/Icon/CloseIcon'
import Loading from 'components/Loading'
import ProgressBar from 'components/ProgressBar'
import useAudioPlayer from 'hooks/useAudioPlayer'
import { GET } from 'shared/axios'
import { Quiz, QuizType, RootStackParamList, WordList } from 'shared/types'
import classNames from 'classnames'
import { FC, useEffect, useMemo, useState } from 'react'
import { Pressable, Text, View } from 'react-native'
import { AnimatableValue } from 'react-native-reanimated'
import { shuffle } from 'yancey-js-util'
import rightAudio from '../../../assets/audios/right.mp3'
import wrongAudio from '../../../assets/audios/wrong.mp3'

export enum AnswerStatus {
  Initial,
  Correct,
  Wrong
}

interface Props extends NativeStackScreenProps<RootStackParamList, 'Quiz'> {
  quizzes: Quiz[]
}

const QuizScreen: FC<Props> = ({ navigation, route }) => {
  const { handleAudioFromLocalFile } = useAudioPlayer()
  const isFocused = useIsFocused()
  const [loading, setLoading] = useState(false)
  const [quizzes, setQuizzes] = useState<Quiz[] | null>(null)
  const [idx, setIdx] = useState(0)
  const [answerInfo, setAnswerInfo] = useState({
    answer: '',
    status: AnswerStatus.Initial
  })
  const currQuiz = useMemo(() => quizzes?.[idx], [idx, quizzes])
  const progress = useMemo(
    () => `${((idx + 1) / (quizzes?.length || 1)) * 100}%` as AnimatableValue,
    [idx, quizzes]
  )

  const backToWordListPage = () => {
    navigation.goBack()
  }

  const toCheckAnswer = () => {
    if (currQuiz?.answers.includes(answerInfo.answer)) {
      setAnswerInfo({ ...answerInfo, status: AnswerStatus.Correct })
      handleAudioFromLocalFile(rightAudio)
    } else {
      setAnswerInfo({ ...answerInfo, status: AnswerStatus.Wrong })
      handleAudioFromLocalFile(wrongAudio)
    }
  }

  const toNextQuiz = () => {
    if (!quizzes) return
    setAnswerInfo({ answer: '', status: AnswerStatus.Initial })

    if (idx < quizzes?.length - 1) {
      setIdx(idx + 1)
    } else {
      setIdx(0)
    }
  }

  const fetchData = async () => {
    setLoading(true)
    try {
      const { data } = await GET<WordList>(`/word/${route.params.id}`)
      setQuizzes(shuffle(data.words.map((word) => word.quizzes).flat()))
    } catch {
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    setIdx(0)
    fetchData()
  }, [isFocused])

  if (loading || !currQuiz) return <Loading />

  return (
    <View className="px-4 flex-1 flex justify-between bg-white relative">
      <View className="flex flex-row items-center py-6">
        <Pressable onPress={backToWordListPage}>
          <CloseIcon />
        </Pressable>
        <ProgressBar progress={progress} />
      </View>

      <View className="flex-1">
        {currQuiz?.type === QuizType.SingleChoice && (
          <View>
            <Text
              className="text-lg font-bold mb-4"
              style={{ fontFamily: 'DINNextRoundedLTW01-Medium' }}
            >
              {currQuiz.question}
            </Text>

            <View className="flex">
              {currQuiz.choices.map((choice) => (
                <Button
                  color="white"
                  variant="outlined"
                  size="large"
                  key={choice}
                  wrapperClassNames="mb-3"
                  selected={choice === answerInfo.answer}
                  onPress={() => {
                    if (answerInfo.status !== AnswerStatus.Initial) {
                      return
                    }

                    setAnswerInfo({ ...answerInfo, answer: choice })
                  }}
                >
                  {choice}
                </Button>
              ))}
            </View>
          </View>
        )}
      </View>

      <View
        className={classNames(
          'px-4 absolute bottom-0 w-screen pb-16 pt-4',
          { 'bg-[#d7ffb8]': answerInfo.status === AnswerStatus.Correct },
          { 'bg-[#ffdfe0]': answerInfo.status === AnswerStatus.Wrong }
        )}
      >
        {answerInfo.status ===
        AnswerStatus.Initial ? null : answerInfo.status ===
          AnswerStatus.Correct ? (
          <>
            <Text
              className="text-[#58a700] text-[24px] leading-[36px]"
              style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
            >
              Nicely done!
            </Text>
            <Text
              className="text-[#58a700] text-[15px] leading-[24px] pt-2 pb-4"
              style={{ fontFamily: 'DINNextRoundedLTW01-Medium' }}
            >
              Translation: {currQuiz.translation}
            </Text>
          </>
        ) : (
          <>
            <Text
              className="text-[#ea2b2b] text-[24px] leading-[36px] pb-[5px]"
              style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
            >
              Correct solution:
            </Text>
            <Text
              className="text-[#ea2b2b] text-[15px] leading-[24px] pb-4"
              style={{ fontFamily: 'DINNextRoundedLTW01-Medium' }}
            >
              {currQuiz.answers.join('')}
            </Text>
          </>
        )}
      </View>

      <Button
        color={answerInfo.status === AnswerStatus.Wrong ? 'red' : 'green'}
        onPress={() => {
          if (!answerInfo.answer) return

          if (answerInfo.status === AnswerStatus.Initial) {
            toCheckAnswer()
          } else {
            toNextQuiz()
          }
        }}
        disabled={!answerInfo.answer}
        wrapperClassNames="mb-5"
      >
        {answerInfo.status !== AnswerStatus.Initial ? 'CONTINUE' : 'CHECK'}
      </Button>
    </View>
  )
}

export default QuizScreen
