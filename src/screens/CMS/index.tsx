import Loading from 'components/Loading'
import { FC, useState } from 'react'
import { WebView } from 'react-native-webview'

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
