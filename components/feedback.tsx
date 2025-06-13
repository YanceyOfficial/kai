import { AnswerStatus, Quiz } from '@/shared/types'
import { cn } from '@/shared/utils'
import { answerInfoAtom } from '@/stores/quiz'
import { useAtomValue } from 'jotai'
import { FC } from 'react'
import { Text, View } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'

interface Props {
  quiz: Quiz
}

const Feedback: FC<Props> = ({ quiz }) => {
  const answerInfo = useAtomValue(answerInfoAtom)
  const { bottom } = useSafeAreaInsets()

  const CorrectFeedback = () => (
    <>
      <Text
        className="text-[24px] leading-[36px] text-[#58a700]"
        style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
      >
        Nicely done!
      </Text>
      <Text
        className="pb-4 pt-2 text-[15px] leading-[24px] text-[#58a700]"
        style={{ fontFamily: 'DINNextRoundedLTW01-Medium' }}
      >
        Translation: {quiz.translation}
      </Text>
    </>
  )

  const WrongFeedback = () => (
    <>
      <Text
        className="pb-[5px] text-[24px] leading-[36px] text-[#ea2b2b]"
        style={{ fontFamily: 'DINNextRoundedLTW01-Bold' }}
      >
        Correct solution:
      </Text>
      <Text
        className="pb-4 text-[15px] leading-[24px] text-[#ea2b2b]"
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
      className={cn(
        'absolute bottom-0 w-screen px-4 pb-16 pt-4',
        bottom > 0 ? 'pb-24' : 'pb-16',
        { 'bg-[#d7ffb8]': answerInfo.status === AnswerStatus.Correct },
        { 'bg-[#ffdfe0]': answerInfo.status === AnswerStatus.Wrong }
      )}
    >
      {renderFeedback()}
    </View>
  )
}

export default Feedback
