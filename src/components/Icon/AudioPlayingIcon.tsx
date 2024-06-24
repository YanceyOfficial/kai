import { FC } from 'react'
import Svg, { ClipPath, Defs, G, Path, Rect } from 'react-native-svg'

interface Props {
  width?: number
  height?: number
  classNames?: string
}

const AudioPlayingIcon: FC<Props> = ({ width, height, classNames }) => {
  return (
    <Svg
      width={width ?? 40}
      height={height ?? 40}
      viewBox="0 0 40 40"
      fill="none"
      className={classNames}
    >
      <G clipPath="url(#clip0_1_259)">
        <Path
          d="M27.8617 0H12.1383C5.43448 0 0 5.43448 0 12.1383V27.8617C0 34.5655 5.43448 40 12.1383 40H27.8617C34.5655 40 40 34.5655 40 27.8617V12.1383C40 5.43448 34.5655 0 27.8617 0Z"
          fill="#4897D2"
        />
        <Path
          d="M27.8617 0H12.1383C5.43448 0 0 5.43448 0 12.1383V24.1024C0 30.8062 5.43448 36.2407 12.1383 36.2407H27.8617C34.5655 36.2407 40 30.8062 40 24.1024V12.1383C40 5.43448 34.5655 0 27.8617 0Z"
          fill="#53ADF0"
        />
        <Path
          d="M25.0565 11.1809C29.6895 12.9551 31.4871 20.8386 24.8221 24.8557"
          stroke="white"
          strokeWidth="2.00854"
          strokeMiterlimit="10"
          strokeLinecap="round"
        />
        <Path
          d="M23.3426 14.8798C25.4683 15.6966 26.2918 19.312 23.2321 21.1565"
          stroke="white"
          strokeWidth="2.00854"
          strokeMiterlimit="10"
          strokeLinecap="round"
        />
        <Path
          d="M19.6536 11.1407L19.61 24.8657C19.6102 24.9706 19.5824 25.0737 19.5297 25.1643C19.4769 25.255 19.4011 25.33 19.3098 25.3817C19.2186 25.4335 19.1153 25.4601 19.0104 25.4588C18.9055 25.4576 18.8029 25.4285 18.7129 25.3746L12.6404 21.7592C12.3577 21.9511 12.0279 22.0622 11.6866 22.0805C11.3454 22.0988 11.0056 22.0237 10.7039 21.8632C10.4023 21.7027 10.1501 21.4629 9.97456 21.1697C9.79905 20.8765 9.70687 20.541 9.70796 20.1992V15.9278C9.70751 15.8155 9.71759 15.7034 9.73809 15.593C9.78712 15.317 9.89732 15.0555 10.0606 14.8276C10.2239 14.5998 10.4361 14.4114 10.6817 14.2762C10.9272 14.1411 11.2 14.0626 11.4798 14.0466C11.7597 14.0306 12.0396 14.0774 12.299 14.1837L18.7732 10.6185C18.8637 10.5682 18.9658 10.5425 19.0694 10.5439C19.1729 10.5454 19.2743 10.5739 19.3633 10.6268C19.4524 10.6796 19.5261 10.7549 19.577 10.845C19.6279 10.9352 19.6543 11.0372 19.6536 11.1407Z"
          fill="white"
        />
        <Path
          d="M9.70796 20.0284V15.9276C9.70751 15.8154 9.71759 15.7033 9.73809 15.5929"
          fill="white"
        />
      </G>
      <Defs>
        <ClipPath id="clip0_1_259">
          <Rect width="40" height="40" fill="white" />
        </ClipPath>
      </Defs>
    </Svg>
  )
}

export default AudioPlayingIcon