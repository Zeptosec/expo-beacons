import { useEvent } from 'expo';
import * as Beacons from 'expo-beacons';
import { useEffect, useState } from 'react';
import { SafeAreaView, ScrollView, Text, TouchableOpacity, View } from 'react-native';
export default function App() {
  // const onChangePayload = useEvent(ExpoBeacons, 'onChange');

  useEffect(() => {
    async function start() {
      // request permissions for scanning beacons
      console.log("asking permissions!")
      const result = await Beacons.requestPermissionsAsync();
      console.log(`granted: `, result)
      if (!result.granted) {
        console.log("Permission for scanning was not granted!");
        return;
      }

      // if permissions were granted start the scan
      console.log("starting scan")
      await Beacons.startScanning([]);
    }
    console.log("useEffect");
    setTimeout(() => start(), 2000);

    // listen for detected beacons
    const listener = Beacons.addBeaconListener(({ data }) => {
      console.log("date", new Date())
      if ("namespace" in data) {
        // detected eddystone
        console.log("Eddystone: ", data)
      } else if ("major" in data) {
        //detected ibeacon
        console.log("iBeacon: ", data)
      }
    });

    // restart eddystone scanning for consistent detection intervals
    // const restartInterval = setInterval(Beacons.restartScanning, 60 * 1000);

    return () => {
      listener.remove();
      // clearInterval(restartInterval)
    }
  }, [])

  function updateIBeaconRegions(uuids: string[]) {
    // update iBeacon monitored regions
    Beacons.updateMonitoredRegions(uuids);
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Module API Example</Text>
        <TouchableOpacity style={styles.button} onPress={() => updateIBeaconRegions([])}>
          <Text>Start 0</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => updateIBeaconRegions(["16967031-4a76-9c35-886d-000050000035"])}>
          <Text>Start 1</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => updateIBeaconRegions(["16967031-4a76-9c35-886d-000090009022"])}>
          <Text>Start 3</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => updateIBeaconRegions(["16967031-4a76-9c35-886d-000050000035", "16967031-4a76-9c35-886d-a0ba3b9eb045"])}>
          <Text>Start 2</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  button: {
    padding: 8
  },
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: '#eee',
  },
  view: {
    flex: 1,
    height: 200,
  },
};
