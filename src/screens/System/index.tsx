import SafeAreaViewWrapper from 'components/SafeAreaViewWrapper'
import { FC, useEffect, useState } from 'react'
import { ScrollView, Text, View } from 'react-native'
import * as DeviceInfo from 'react-native-device-info'

const Item: FC<{
  name: string
  value: string | number
}> = ({ name, value }) => (
  <Text className="mb-4">
    <Text className="font-bold">{name}: </Text>
    {value}
  </Text>
)

const System: FC = () => {
  const [deviceToken, setDeviceToken] = useState('')

  const availableLocationProviders =
    DeviceInfo.getAvailableLocationProvidersSync()

  const powerStateSync = DeviceInfo.getPowerStateSync()

  const getDeviceToken = async () => {
    try {
      const token = await DeviceInfo.getDeviceToken()
      setDeviceToken(token)
    } catch {}
  }

  useEffect(() => {
    getDeviceToken()
  }, [])

  return (
    <SafeAreaViewWrapper wrapperClassNames="justify-start">
      <ScrollView className="mt-4">
        <Item name="Application Name" value={DeviceInfo.getApplicationName()} />

        <View>
          <Text className="font-bold">Available Location Providers:</Text>
          <View className="ml-4 mt-4">
            {Object.keys(availableLocationProviders).map((provider) => (
              <Item
                key={provider}
                name={provider}
                value={availableLocationProviders[provider].toString()}
              />
            ))}
          </View>
        </View>

        <Item name="Build Id" value={DeviceInfo.getBuildIdSync()} />
        <Item name="Battery Level" value={DeviceInfo.getBatteryLevelSync()} />
        <Item name="Brand" value={DeviceInfo.getBrand()} />
        <Item name="Build Number" value={DeviceInfo.getBuildNumber()} />
        <Item name="Bundle Id" value={DeviceInfo.getBundleId()} />
        <Item name="Carrier" value={DeviceInfo.getCarrierSync()} />
        <Item name="Device Id" value={DeviceInfo.getDeviceId()} />
        <Item name="Device Type" value={DeviceInfo.getDeviceType()} />
        <Item name="Device Name" value={DeviceInfo.getDeviceNameSync()} />
        <Item name="Device Token" value={deviceToken} />
        <Item
          name="First Install Name"
          value={DeviceInfo.getFirstInstallTimeSync()}
        />
        <Item name="Font Scale" value={DeviceInfo.getFontScaleSync()} />
        <Item
          name="Free Disk Storage"
          value={DeviceInfo.getFreeDiskStorageSync()}
        />
        <Item
          name="Free Disk Storage Old"
          value={DeviceInfo.getFreeDiskStorageOldSync()}
        />
        <Item name="Ip Address" value={DeviceInfo.getIpAddressSync()} />
        <Item name="Carrier" value={DeviceInfo.getApplicationName()} />

        <Item
          name="Installer Package Name"
          value={DeviceInfo.getInstallerPackageNameSync()}
        />
        <Item name="Mac Address" value={DeviceInfo.getMacAddressSync()} />
        <Item name="Manufacturer" value={DeviceInfo.getManufacturerSync()} />
        <Item name="Model" value={DeviceInfo.getModel()} />

        <View>
          <Text className="font-bold">Power State:</Text>
          <View className="ml-4 mt-4">
            {Object.keys(powerStateSync).map((item) => (
              <Item
                key={item}
                name={item}
                value={powerStateSync[item].toString()}
              />
            ))}
          </View>
        </View>

        <Item name="Readable Version" value={DeviceInfo.getReadableVersion()} />
        <Item name="System Name" value={DeviceInfo.getSystemName()} />
        <Item name="System Version" value={DeviceInfo.getSystemVersion()} />
        <Item
          name="Total Disk Capacity"
          value={DeviceInfo.getTotalDiskCapacitySync()}
        />
        <Item
          name="Total Disk Capacity Old"
          value={DeviceInfo.getTotalDiskCapacityOldSync()}
        />
        <Item name="Total Memory" value={DeviceInfo.getTotalMemorySync()} />
        <Item name="Unique Id" value={DeviceInfo.getUniqueIdSync()} />
        <Item name="Used Memory" value={DeviceInfo.getUsedMemorySync()} />
        <Item name="Version" value={DeviceInfo.getVersion()} />
        <Item name="Brightness" value={DeviceInfo.getBrightnessSync()} />
        <Item name="Has Notch" value={DeviceInfo.hasNotch().toString()} />
        <Item
          name="Has Dynamic Island"
          value={DeviceInfo.hasDynamicIsland().toString()}
        />
        <Item
          name="Is Battery Charging"
          value={DeviceInfo.isBatteryChargingSync().toString()}
        />
        <Item
          name="Is Emulator"
          value={DeviceInfo.isEmulatorSync().toString()}
        />
        <Item
          name="Is Landscape"
          value={DeviceInfo.isLandscapeSync().toString()}
        />
        <Item
          name="Is Location Enabled"
          value={DeviceInfo.isLocationEnabledSync().toString()}
        />
        <Item
          name="Is Headphones Connected"
          value={DeviceInfo.isHeadphonesConnectedSync().toString()}
        />
        <Item
          name="Is Wired Headphones Connected"
          value={DeviceInfo.isWiredHeadphonesConnectedSync().toString()}
        />
        <Item
          name="Is Bluetooth Headphones Connected"
          value={DeviceInfo.isBluetoothHeadphonesConnectedSync().toString()}
        />
        <Item
          name="Is Pin Or Fingerprint Set"
          value={DeviceInfo.isPinOrFingerprintSetSync().toString()}
        />
        <Item name="Is Tablet" value={DeviceInfo.isTablet().toString()} />
        <Item
          name="Is Display Zoomed"
          value={DeviceInfo.isDisplayZoomed().toString()}
        />
        <Item
          name="Supported Abis"
          value={DeviceInfo.supportedAbisSync().join('; ')}
        />
      </ScrollView>
    </SafeAreaViewWrapper>
  )
}

export default System
