import { FC } from 'react'
import { Text, View } from 'react-native'
import { getApplicationName } from 'react-native-device-info'

const System: FC = () => {
  return (
    <View>
      <Text>{getApplicationName()}</Text>
    </View>
  )
}

export default System
