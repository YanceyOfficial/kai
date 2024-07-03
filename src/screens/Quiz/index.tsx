import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import Button from 'components/Button'
import CloseIcon from 'components/Icon/CloseIcon'
import Loading from 'components/Loading'
import ProgressBar from 'components/ProgressBar'
import useAudioPlayer from 'hooks/useAudioPlayer'
import { useAtom } from 'jotai'
import { FC, useEffect, useMemo, useState } from 'react'
import { Pressable, View } from 'react-native'
import { AnimatableValue } from 'react-native-reanimated'
import { GET } from 'shared/axios'
import {
  AnswerStatus,
  Quiz,
  QuizType,
  RootStackParamList,
  WordList
} from 'shared/types'
import { answerInfoAtom, quizIdxAtom, quizzesAtom } from 'stores/quiz'
import { shuffle } from 'yancey-js-util'
import rightAudio from '../../../assets/audios/right.mp3'
import wrongAudio from '../../../assets/audios/wrong.mp3'
import Feedback from './Feedback'
import SingleChoice from './SingleChoice'
import SplitCombine from './SpiltCombine'
import { checkAnswer } from './checkAnswer'

type Props = NativeStackScreenProps<RootStackParamList, 'Quiz'>

const QuizScreen: FC<Props> = ({ navigation, route }) => {
  const { handleAudioFromLocalFile } = useAudioPlayer()
  const isFocused = useIsFocused()

  const [quizzes, setQuizzes] = useAtom(quizzesAtom)
  const [quizIdx, setQuizIdx] = useAtom(quizIdxAtom)
  const [answerInfo, setAnswerInfo] = useAtom(answerInfoAtom)
  const [loading, setLoading] = useState(false)

  const quiz = useMemo(() => quizzes?.[quizIdx], [quizIdx, quizzes])
  const progress = useMemo(
    () =>
      `${((quizIdx + 1) / (quizzes?.length || 1)) * 100}%` as AnimatableValue,
    [quizIdx, quizzes]
  )

  const backToWordListPage = () => {
    navigation.replace('Home')
  }

  const toCheckAnswer = () => {
    if (!quiz) return

    const isCorrect = checkAnswer(answerInfo, quiz)
    if (isCorrect) {
      setAnswerInfo({ ...answerInfo, status: AnswerStatus.Correct })
      handleAudioFromLocalFile(rightAudio)
    } else {
      setAnswerInfo({ ...answerInfo, status: AnswerStatus.Wrong })
      handleAudioFromLocalFile(wrongAudio)
    }
  }

  const toNextQuiz = () => {
    if (!quizzes) return
    setAnswerInfo({ answers: [], status: AnswerStatus.Unanswered })

    if (quizIdx < quizzes?.length - 1) {
      setQuizIdx(quizIdx + 1)
    } else {
      navigation.replace('Home')
    }
  }

  const handleConfirm = () => {
    if (!answerInfo.answers.every(Boolean)) return

    if (answerInfo.status === AnswerStatus.Unanswered) {
      toCheckAnswer()
    } else {
      toNextQuiz()
    }
  }

  const fetchData = async () => {
    setLoading(true)
    try {
      const { data } = await GET<WordList>(`/word/${route.params.id}`)
      const splitCombineQuizzes: Quiz[] = data.words.map((word) => ({
        _id: word._id,
        question: word.name,
        answers: [word.name],
        choices: word.syllabification,
        translation: word.explanation,
        type: QuizType.SplitCombine
      }))
      setQuizzes(
        shuffle([
          ...data.words
            .map((word) => word.quizzes)
            .flat()
            .map((quiz) => ({ ...quiz, choices: shuffle(quiz.choices) })),
          ...splitCombineQuizzes.map((quiz) => ({
            ...quiz,
            choices: shuffle(quiz.choices)
          }))
        ])
      )
    } catch {
    } finally {
      setLoading(false)
    }
  }

  const renderQuizByType = () => {
    if (!quiz) return null

    switch (true) {
      case quiz.type === QuizType.SingleChoice:
        return <SingleChoice quiz={quiz} />
      case quiz.type === QuizType.SplitCombine:
        return <SplitCombine quiz={quiz} />
      default:
        return null
    }
  }

  useEffect(() => {
    fetchData()
  }, [isFocused])

  if (loading || !quiz) return <Loading fullScreen />

  return (
    <View className="px-4 flex-1 flex justify-between bg-white relative">
      <View className="flex flex-row items-center py-6">
        <Pressable onPress={backToWordListPage}>
          <CloseIcon />
        </Pressable>
        <ProgressBar progress={progress} />
      </View>

      <View className="flex-1">{renderQuizByType()}</View>
      <Feedback quiz={quiz} />

      <Button
        color={answerInfo.status === AnswerStatus.Wrong ? 'red' : 'green'}
        onPress={handleConfirm}
        disabled={answerInfo.answers.length === 0}
        wrapperClassNames="mb-5"
      >
        {answerInfo.status !== AnswerStatus.Unanswered ? 'CONTINUE' : 'CHECK'}
      </Button>
    </View>
  )
}

export default QuizScreen
