import classNames from 'classnames'
import { useAtomValue } from 'jotai'
import { FC } from 'react'
import { Text, View } from 'react-native'
import { AnswerStatus, Quiz } from 'shared/types'
import { answerInfoAtom } from 'stores/quiz'

interface Props {
  quiz: Quiz
}

const Feedback: FC<Props> = ({ quiz }) => {
  const answerInfo = useAtomValue(answerInfoAtom)

  const CorrectFeedback = () => (
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
        Translation: {quiz.translation}
      </Text>
    </>
  )

  const WrongFeedback = () => (
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
        {quiz.answers.join('')}
      </Text>
    </>
  )

  const renderFeedback = () => {
    switch (true) {
      case answerInfo.status === AnswerStatus.Correct:
        return <CorrectFeedback />
      case answerInfo.status === AnswerStatus.Wrong:
        return <WrongFeedback />
      default:
        return null
    }
  }

  return (
    <View
      className={classNames(
        'px-4 absolute bottom-0 w-screen pb-16 pt-4',
        { 'bg-[#d7ffb8]': answerInfo.status === AnswerStatus.Correct },
        { 'bg-[#ffdfe0]': answerInfo.status === AnswerStatus.Wrong }
      )}
    >
      {renderFeedback()}
    </View>
  )
}

export default Feedback
