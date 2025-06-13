import Button from '@/components/button'
import Feedback from '@/components/feedback'
import Loading from '@/components/full-text-loading'
import ProgressBar from '@/components/progress-bar'
import SafeAreaViewWrapper from '@/components/safe-area-view-wrapper'
import SingleChoice from '@/components/single-choice'
import SplitCombine from '@/components/spilt-combine'
import { DEFAULT_PAGE_SIZE } from '@/shared/constants'
import { AnswerStatus, Quiz, QuizType, WordList } from '@/shared/types'
import { checkAnswer } from '@/shared/utils'
import { answerInfoAtom, quizIdxAtom } from '@/stores/quiz'
import { useAudioPlayer } from 'expo-audio'
import { useLocalSearchParams } from 'expo-router'
import { useAtom } from 'jotai'
import { useMemo } from 'react'
import { View } from 'react-native'
import { AnimatableValue } from 'react-native-reanimated'
import useSWR from 'swr'
import { shuffle } from 'yancey-js-util'

const QuizScreen = () => {
  const params = useLocalSearchParams()
  const rightAudio = useAudioPlayer(require('@/assets/audios/right.mp3'))
  const wrongAudio = useAudioPlayer(require('@/assets/audios/wrong.mp3'))
  const [quizIdx, setQuizIdx] = useAtom(quizIdxAtom)
  const [answerInfo, setAnswerInfo] = useAtom(answerInfoAtom)
  const { isLoading, data } = useSWR<WordList>(
    `/word?page=${params.page}&pageSize=${DEFAULT_PAGE_SIZE}`
  )
  const quizzes = useMemo(() => {
    if (!data) return []
    const splitCombineQuizzes: Quiz[] = data.items
      .filter(
        (word) =>
          word.name.split(' ').length === 1 &&
          !word.name.includes('-') &&
          [...new Set(word.syllabification)].length ===
            word.syllabification.length
      )
      .map((word) => ({
        _id: word._id,
        question: word.name,
        answers: [word.name],
        choices: word.syllabification,
        translation: word.explanation,
        type: QuizType.SplitCombine
      }))

    return shuffle([
      ...data.items
        .map((word) => word.quizzes)
        .flat()
        .map((quiz) => ({ ...quiz, choices: shuffle(quiz.choices) })),
      ...splitCombineQuizzes.map((quiz) => ({
        ...quiz,
        choices: shuffle(quiz.choices)
      }))
    ]) as Quiz[]
  }, [data])

  const quiz = useMemo(() => quizzes?.[quizIdx], [quizIdx, quizzes])
  const progress = useMemo(
    () =>
      `${((quizIdx + 1) / (quizzes?.length || 1)) * 100}%` as AnimatableValue,
    [quizIdx, quizzes]
  )

  const toCheckAnswer = () => {
    if (!quiz) return

    const isCorrect = checkAnswer(answerInfo, quiz)
    if (isCorrect) {
      setAnswerInfo({ ...answerInfo, status: AnswerStatus.Correct })
      rightAudio.play()
    } else {
      setAnswerInfo({ ...answerInfo, status: AnswerStatus.Wrong })
      wrongAudio.play()
    }
  }

  const toNextQuiz = () => {
    if (!quizzes) return
    setAnswerInfo({ answers: [], status: AnswerStatus.Unanswered })

    if (quizIdx < quizzes?.length - 1) {
      setQuizIdx(quizIdx + 1)
    } else {
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

  if (isLoading || !quiz) return <Loading fullScreen />

  return (
    <SafeAreaViewWrapper
      headerRightComp={
        <ProgressBar progress={progress} wrapperClassNames="ml-4" />
      }
    >
      <View className="flex-1 pt-8">{renderQuizByType()}</View>
      <Feedback quiz={quiz} />

      <Button
        color={answerInfo.status === AnswerStatus.Wrong ? 'red' : 'green'}
        onPress={handleConfirm}
        disabled={answerInfo.answers.length === 0}
      >
        {answerInfo.status !== AnswerStatus.Unanswered ? 'CONTINUE' : 'CHECK'}
      </Button>
    </SafeAreaViewWrapper>
  )
}

export default QuizScreen
