import { FC, useState } from 'react'
import { WebView } from 'react-native-webview'
import Loading from 'src/components/Loading'

const CmsWebview: FC = () => {
  const [loading, setLoading] = useState(false)
  return (
    <>
      {loading && <Loading fullScreen />}
      <WebView
        source={{ uri: 'https://kai.yancey.app/' }}
        className={loading ? 'hidden' : ''}
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

export default CmsWebview
