/**
 * @format
 */

import * as Sentry from '@sentry/react-native'
import { AppRegistry } from 'react-native'
import Config from 'react-native-config'
import { name as appName } from './app.json'
import App from './src/App'

Sentry.init({
  dsn: Config.SENTRY_DSN,
  tracesSampleRate: 1.0,
  _experiments: {
    profilesSampleRate: 1.0
  }
})

AppRegistry.registerComponent(appName, () => Sentry.wrap(App))
