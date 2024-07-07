import { FC, useState } from 'react'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { WebView } from 'react-native-webview'
import Loading from 'src/components/Loading'

const CmsWebview: FC = () => {
  const [loading, setLoading] = useState(false)
  const { top } = useSafeAreaInsets()
  return (
    <>
      {loading && <Loading fullScreen />}
      <WebView
        source={{ uri: `https://kai.yancey.app/?safeAreaTop=${top}` }}
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
