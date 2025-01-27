import { Image, StyleSheet, Platform, EventSubscription, Button } from 'react-native';
import * as Beacons from 'expo-beacons';
import { HelloWave } from '@/components/HelloWave';
import ParallaxScrollView from '@/components/ParallaxScrollView';
import { ThemedText } from '@/components/ThemedText';
import { ThemedView } from '@/components/ThemedView';
import { useEffect, useState } from 'react';

export default function HomeScreen() {
  const [granted, setGranted] = useState<boolean>();

  useEffect(() => {
    let listener: any;
    async function start() {
      const perms = await Beacons.requestPermissionsAsync();

      if (perms) {
        await Beacons.startScanning([]);
        listener = Beacons.addBeaconListener(event => {
          console.log(event.data);
        })
      }
    }
    start();
    return () => {
      listener?.remove();
    }
  })

  function updateRegions(uuids: string[]) {
    console.log(`updated regions: ${uuids}`)
    Beacons.updateMonitoredRegions(uuids);
  }

  return (
    <ParallaxScrollView
      headerBackgroundColor={{ light: '#A1CEDC', dark: '#1D3D47' }}
      headerImage={
        <Image
          source={require('@/assets/images/partial-react-logo.png')}
          style={styles.reactLogo}
        />
      }>
      <Button title='UUIDS 0' onPress={() => updateRegions([])} />
      <Button title='UUIDS 1' onPress={() => updateRegions(["16967031-4a76-9c35-886d-000050000035"])} />
      <Button title='UUIDS 2' onPress={() => updateRegions(["16967031-4a76-9c35-886d-a0ba3b9eb045"])} />
      <Button title='UUIDS 2' onPress={() => updateRegions(["16967031-4a76-9c35-886d-000050000035", "16967031-4a76-9c35-886d-a0ba3b9eb045"])} />
      <ThemedView style={styles.titleContainer}>
        <ThemedText type="title">Welcome!</ThemedText>
        <HelloWave />
      </ThemedView>
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">Step 1: Try it</ThemedText>
        <ThemedText>
          Edit <ThemedText type="defaultSemiBold">app/(tabs)/index.tsx</ThemedText> to see changes.
          Press{' '}
          <ThemedText type="defaultSemiBold">
            {Platform.select({
              ios: 'cmd + d',
              android: 'cmd + m',
              web: 'F12'
            })}
          </ThemedText>{' '}
          to open developer tools.
        </ThemedText>
      </ThemedView>
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">Step 2: Explore</ThemedText>
        <ThemedText>
          Tap the Explore tab to learn more about what's included in this starter app.
        </ThemedText>
      </ThemedView>
      <ThemedView style={styles.stepContainer}>
        <ThemedText type="subtitle">Step 3: Get a fresh start</ThemedText>
        <ThemedText>
          When you're ready, run{' '}
          <ThemedText type="defaultSemiBold">npm run reset-project</ThemedText> to get a fresh{' '}
          <ThemedText type="defaultSemiBold">app</ThemedText> directory. This will move the current{' '}
          <ThemedText type="defaultSemiBold">app</ThemedText> to{' '}
          <ThemedText type="defaultSemiBold">app-example</ThemedText>.
        </ThemedText>
      </ThemedView>
    </ParallaxScrollView>
  );
}

const styles = StyleSheet.create({
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  stepContainer: {
    gap: 8,
    marginBottom: 8,
  },
  reactLogo: {
    height: 178,
    width: 290,
    bottom: 0,
    left: 0,
    position: 'absolute',
  },
});
