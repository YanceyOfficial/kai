import { FC } from 'react'
import { Text } from 'react-native'
import { getApplicationName } from 'react-native-device-info'
import { SafeAreaView } from 'react-native-safe-area-context'

const System: FC = () => {
  return (
    <SafeAreaView className="p-4">
      <Text>Application Name: {getApplicationName()}</Text>
    </SafeAreaView>
  )
}

export default System
