import { FC } from 'react'
import Svg, { Path } from 'react-native-svg'

interface Props {
  classNames?: string
}

const CloseIcon: FC<Props> = ({ classNames }) => {
  return (
    <Svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      className={classNames}
    >
      <Path
        d="M2 2L22 22"
        stroke="#ADADAD"
        strokeWidth="2.5"
        strokeLinecap="round"
      />
      <Path
        d="M22 2L2 22"
        stroke="#ADADAD"
        strokeWidth="2.5"
        strokeLinecap="round"
      />
    </Svg>
  )
}

export default CloseIcon
