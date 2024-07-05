import classNames from 'classnames'
import Button from 'components/Button'
import { useAtom } from 'jotai'
import { FC } from 'react'
import { Text, View, useColorScheme } from 'react-native'
import { answerInfoAtom } from 'stores/quiz'
import { AnswerStatus, Quiz } from 'types'

interface Props {
  quiz: Quiz
}

const SingleChoice: FC<Props> = ({ quiz }) => {
  const isDarkMode = useColorScheme() === 'dark'
  const [answerInfo, setAnswerInfo] = useAtom(answerInfoAtom)

  return (
    <View>
      <Text
        className={classNames(
          'text-lg font-bold mb-4',
          isDarkMode ? 'text-[#f1f7fb]' : 'text-[#3c3c3c]'
        )}
        style={{ fontFamily: 'DINNextRoundedLTW01-Medium' }}
      >
        {quiz.question}
      </Text>

      <View className="flex">
        {quiz.choices.map((choice, i) => (
          <Button
            color="white"
            variant="outlined"
            size="large"
            key={i}
            wrapperClassNames="mb-3"
            selected={choice === answerInfo.answers[0]}
            onPress={() => {
              if (answerInfo.status !== AnswerStatus.Unanswered) {
                return
              }

              setAnswerInfo({ ...answerInfo, answers: [choice] })
            }}
          >
            {choice}
          </Button>
        ))}
      </View>
    </View>
  )
}

export default SingleChoice
