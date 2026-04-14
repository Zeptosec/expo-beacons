import ExpoBeacons, { useBluetoothState, useIsScanning, usePermissions } from 'expo-beacons';
import { useEffect } from 'react';
import { Button, ScrollView, StyleSheet, Text, View } from 'react-native';
import useDetectedBeacons from './hooks/useDetectedBeacons';
import BeaconInfo from './components/BeaconInfo';

export default function App() {
  const bluetoothState = useBluetoothState();
  const isScanning = useIsScanning();
  const beacons = useDetectedBeacons();
  const { permissions } = usePermissions();

  useEffect(() => {
    const listener = ExpoBeacons.addListener("onBeaconDetected", data => {
      console.log("Beacon detected!", data);
    });

    return () => {
      listener.remove();
    };
  }, [])

  async function requestBluetoothEnable() {
    try {
      await ExpoBeacons.requestBluetoothEnable();
    } catch (error) {
      console.error('Failed to request Bluetooth enable:', error);
    }
  }

  async function requestBluetoothPermissions() {
    try {
      const result = await ExpoBeacons.requestPermissionsAsync();
      console.log('Bluetooth permissions result:', result);
    } catch (error) {
      console.error('Failed to request Bluetooth permissions:', error);
    }
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 60, paddingTop: 20 }} contentInsetAdjustmentBehavior="automatic">
      <Text style={styles.header}>Module API Example</Text>
      <Group name="Async functions">
        <View style={{ rowGap: 12 }}>

          <Button
            title="Request Bluetooth Permissions"
            onPress={requestBluetoothPermissions}
          />

          <Button
            title="Request Bluetooth Enable"
            onPress={requestBluetoothEnable}
          />

          <Button
            title="Start Scan"
            onPress={() => ExpoBeacons.startScan()}
          />

          <Button
            title="Stop Scan"
            onPress={() => ExpoBeacons.stopScan()}
          />

          <Button
            title="Set Regions 1"
            onPress={() => ExpoBeacons.setRegions(['16967031-4a76-9c35-886d-000050000035'])}
          />

          <Button
            title="Set Region 2"
            onPress={() => ExpoBeacons.setRegions(['16967031-4a76-9c35-886d-000090009022'])}
          />

          <Button
            title="Clear Regions"
            onPress={() => ExpoBeacons.setRegions([])}
          />


        </View>
      </Group>
      <Group name="Events">
        <Text>Bluetooth State: {bluetoothState}</Text>
        <Text>Is Scanning: {isScanning.toString()}</Text>
      </Group>
      <Group name="Detected Beacons">
        {beacons.beacons.length > 0 ? (
          <Button title="Clear Beacons" onPress={beacons.clearBeacons} />
        ) : (
          <Text>No beacons detected yet...</Text>
        )}
        {beacons.beacons.map((detectedBeacon) => (
          <BeaconInfo key={`${detectedBeacon.beacon.uuid}-${detectedBeacon.beacon.address}`} detectedBeacon={detectedBeacon} />
        ))}
      </Group>
      <Group name="Permissions">
        <Text>Granted: {permissions.granted.toString()}</Text>
        {permissions.permissions && Object.entries(permissions.permissions).map(([permissionName, info]) => (
          <View key={permissionName} style={{ marginBottom: 12 }}>
            <Text style={{ fontWeight: 'bold' }}>{permissionName}</Text>
            <Text>Status: {info.status}</Text>
            <Text>Granted: {info.granted.toString()}</Text>
          </View>
        ))}
      </Group>
    </ScrollView>
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

const styles = StyleSheet.create({
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
  },
  group: {
    margin: 12,
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
});
