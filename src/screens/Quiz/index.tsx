import { useIsFocused } from '@react-navigation/native'
import { NativeStackScreenProps } from '@react-navigation/native-stack'
import { FC, useEffect, useMemo, useState } from 'react'
import { Pressable, Text, View } from 'react-native'
import { AnimatableValue } from 'react-native-reanimated'
import { shuffle } from 'yancey-js-util'
import rightAudio from '../../../assets/audios/right.mp3'
import Button from '../../components/Button'
import CloseIcon from '../../components/Icon/CloseIcon'
import Loading from '../../components/Loading'
import ProgressBar from '../../components/ProgressBar'
import { GET } from '../../shared/axios'
import {
  Quiz,
  QuizType,
  RootStackParamList,
  WordList
} from '../../shared/types'

interface Props extends NativeStackScreenProps<RootStackParamList, 'Quiz'> {
  quizzes: Quiz[]
}

const QuizScreen: FC<Props> = ({ navigation }) => {
  const isFocused = useIsFocused()
  const [loading, setLoading] = useState(false)
  const [quizzes, setQuizzes] = useState<Quiz[] | null>(null)
  const [idx, setIdx] = useState(0)
  const [answer, setAnswer] = useState('')
  const currQuiz = useMemo(() => quizzes?.[idx], [idx, quizzes])
  const progress = useMemo(
    () => `${((idx + 1) / (quizzes?.length || 1)) * 100}%` as AnimatableValue,
    [idx, quizzes]
  )

  const backToWordListPage = () => {
    navigation.goBack()
  }

  const toNextQuiz = () => {
    if (!quizzes) return

    if (idx < quizzes?.length - 1) {
      setIdx(idx + 1)
    } else {
      setIdx(0)
    }
  }

  const fetchData = async () => {
    setLoading(true)
    try {
      const { data } = await GET<WordList>(
        `/word/916d39a9-1d93-41f7-94d9-df18b77a2548`
      )
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
    <View className="px-4 flex-1 flex justify-between bg-white">
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
                  selected={choice === answer}
                  onPress={() => setAnswer(choice)}
                >
                  {choice}
                </Button>
              ))}
            </View>
          </View>
        )}
      </View>

      <View className="bg-[#d7ffb8] py-4 -mx-4 px-4">
        <Text
          className="text-[#58a700] text-[24px] leading-[36px] pb-4"
          style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
        >
          Nicely done!
        </Text>
        <Button
          color="green"
          onPress={toNextQuiz}
          disabled={!answer}
          soundSource={rightAudio}
        >
          CHECK
        </Button>
      </View>
      {/* <View className="bg-[#ffdfe0] py-4 -mx-4 px-4">
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
          Yes, I've never been there before.
        </Text>
        <Button
          color="red"
          onPress={toNextQuiz}
          disabled={!answer}
          soundSource={wrongAudio}
        >
          CONTINUE
        </Button>
      </View> */}
    </View>
  )
}

export default QuizScreen
