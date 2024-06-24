import { FC, useState } from 'react'
import { DimensionValue, View } from 'react-native'

interface Props {
  progress: DimensionValue
}

const ProgressBar: FC<Props> = ({ progress }) => {
  const [width, setWidth] = useState(0)

  return (
    <View className="flex-1 bg-[#E5E5E5] rounded-3xl h-5 ml-4">
      <View
        className={`bg-[#93d333] h-5 rounded-3xl relative`}
        style={{ width: progress }}
        onLayout={(event) => {
          const { width } = event.nativeEvent.layout
          setWidth(width)
        }}
      >
        <View
          className="bg-[#fff] h-[6px] rounded top-1 left-[8px] opacity-20"
          style={{ width: width - 16 }}
        />
      </View>
    </View>
  )
}

export default ProgressBar
