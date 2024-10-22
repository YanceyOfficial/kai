import {
  createNavigationContainerRef,
  ParamListBase
} from '@react-navigation/native'
import { RootStackParamList } from 'src/types'

export const navigationRef = createNavigationContainerRef<RootStackParamList>()

export const navigate = <RouteName extends keyof ParamListBase>(
  ...args: // this first condition allows us to iterate over a union type
  // This is to avoid getting a union of all the params from `ParamListBase[RouteName]`,
  // which will get our types all mixed up if a union RouteName is passed in.
  RouteName extends unknown
    ? // This condition checks if the params are optional,
      // which means it's either undefined or a union with undefined
      undefined extends ParamListBase[RouteName]
      ?
          | [screen: RouteName] // if the params are optional, we don't have to provide it
          | [screen: RouteName, params: ParamListBase[RouteName]]
      : [screen: RouteName, params: ParamListBase[RouteName]]
    : never
) => {
  if (navigationRef.isReady()) {
    // @ts-ignore
    navigationRef.navigate(...args)
  }
}
