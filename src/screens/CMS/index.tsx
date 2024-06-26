import { FC, useState } from 'react'
import { WebView } from 'react-native-webview'
import Loading from '../../components/Loading'

const MyScreen: FC = () => {
  const [loading, setLoading] = useState(false)
  return (
    <>
      {loading && <Loading />}
      <WebView
        source={{ uri: 'https://kai.yancey.app/' }}
        style={{ flex: 1 }}
        onLoadStart={() => {
          setLoading(true)
        }}
        onLoadEnd={() => {
          setLoading(false)
        }}
      />
    </>
  )
}

export default MyScreen
