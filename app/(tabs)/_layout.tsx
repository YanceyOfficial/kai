import { HapticTab } from '@/components/haptic-tab'
import { IconSymbol } from '@/components/icon-symbol'
import TabBarBackground from '@/components/tab-bar-background'
import { useColorScheme } from '@/hooks/use-color-scheme'
import { Colors } from '@/shared/colors'
import { Tabs } from 'expo-router'
import React from 'react'
import { Platform } from 'react-native'

export default function TabLayout() {
  const colorScheme = useColorScheme()

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: Colors[colorScheme ?? 'light'].tint,
        headerShown: false,
        tabBarButton: HapticTab,
        tabBarBackground: TabBarBackground,
        tabBarStyle: Platform.select({
          ios: {
            position: 'absolute'
          },
          default: {}
        })
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Word List',
          tabBarIcon: ({ color }) => (
            <IconSymbol size={28} name="house.fill" color={color} />
          )
        }}
      />
      <Tabs.Screen
        name="my"
        options={{
          title: 'My',
          tabBarIcon: ({ color }) => (
            <IconSymbol size={28} name="paperplane.fill" color={color} />
          )
        }}
      />
    </Tabs>
  )
}
