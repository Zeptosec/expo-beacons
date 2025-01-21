import { useEvent } from 'expo';
import * as Beacons from 'expo-beacons';
import { useEffect, useState } from 'react';
import { Button, EventSubscription, Pressable, SafeAreaView, ScrollView, Text, TouchableOpacity, View } from 'react-native';
// ["16967031-4a76-9c35-886d-000050000035"]
export default function App() {
  // const onChangePayload = useEvent(ExpoBeacons, 'onChange');
  const [granted, setGranted] = useState<boolean>();

  useEffect(() => {
    let listener: EventSubscription | undefined;
    async function reqPerms() {
      const perm = await Beacons.requestPermissionsAsync();
      setGranted(perm);
      console.log(`req perms: ${perm}`)
      if (perm) {
        await Beacons.startScanning([]);
        listener = Beacons.addBeaconListener((event) => {
          console.log(event.data);
        }) as any;
      }
    }
    reqPerms()
    return () => {
      listener?.remove();
    }
  }, [])

  function start(uuids: string[]) {
    if (!granted) return;
    Beacons.updateMonitoredRegions(uuids);
    console.log("started scan");
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Module API Example</Text>
        <TouchableOpacity style={styles.button} onPress={() => start([])}>
          <Text>Start 0</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => start(["16967031-4a76-9c35-886d-000050000035"])}>
          <Text>Start 1</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => start(["16967031-4a76-9c35-886d-000050000035", "16967031-4a76-9c35-886d-a0ba3b9eb045"])}>
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
