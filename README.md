# expo-beacons

Library for detecting iBeacons and Eddystones for iOS and Android.

## Limitations

iOS doesn't allow ranging for unknown iBeacons, so you will have to provide a list of UUIDs to filter for. Android doesn't have this limitation and will detect all beacons in range. But you don't need a filter for eddystones, so they will be detected on both platforms without any configuration.

## Installation

```bash
npx expo install expo-beacons
```

## Quick Start Example

```tsx
import React, { useEffect } from 'react';
import { View, Text, Button, ScrollView, Platform } from 'react-native';
import ExpoBeacons, { 
  useBluetoothState, 
  useIsScanning, 
  usePermissions,
  Beacon 
} from 'expo-beacons';

export default function App() {
  const bluetoothState = useBluetoothState();
  const isScanning = useIsScanning();
  const { permissions } = usePermissions();

  useEffect(() => {
    // Listen for detected beacons
    const listener = ExpoBeacons.addListener("onBeaconDetected", (beacon: Beacon) => {
      console.log("Detected:", beacon);
    });

    return () => listener.remove();
  }, []);

  const handleStartScan = () => {
    try {
      if (Platform.OS === 'ios') {
        // for iOS we need to set regions to filter for.
        ExpoBeacons.setRegions(['16967031-4a76-9c35-886d-000050000123']);
      }
      ExpoBeacons.startScan();
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <ScrollView style={{ padding: 20, paddingTop: 60 }}>
      <Text>Bluetooth: {bluetoothState}</Text>
      <Text>Scanning: {isScanning ? 'Yes' : 'No'}</Text>
      <Text>Permissions Granted: {permissions.granted ? 'Yes' : 'No'}</Text>
      
      <Button title="Request Permissions" onPress={() => ExpoBeacons.requestPermissionsAsync()} />
      <Button title="Start Scanning" onPress={handleStartScan} />
      <Button title="Stop Scanning" onPress={() => ExpoBeacons.stopScan()} />
    </ScrollView>
  );
}
```

## API Reference

### Functions

| Method | Return Type | Description |
| :--- | :--- | :--- |
| `requestPermissionsAsync()` | `Promise<PermissionsResponse>` | Requests required location and bluetooth permissions. Returns current status. |
| `requestBluetoothEnable()` | `Promise<void>` | (Android only) Requests the user to enable Bluetooth if it is off. |
| `startScan()` | `void` | Starts the beacon scanner. Requires permissions and Bluetooth to be enabled. |
| `stopScan()` | `void` | Stops the active beacon scanner. |
| `setRegions(uuids: string[])` | `void` | Sets the UUIDs to filter for. Pass an empty array to clear filters. |

### Hooks

| Hook | Return Type | Description |
| :--- | :--- | :--- |
| `useBluetoothState()` | `'on' \| 'off' \| 'unknown'` | Returns and subscribes to the current Bluetooth hardware state. |
| `useIsScanning()` | `boolean` | Returns and subscribes to whether the scanner is currently active. |
| `usePermissions()` | `{ permissions: PermissionsResponse, requestPermissions: () => Promise<PermissionsResponse> }` | Returns and subscribes to the app's permission status. |

### Events

| Event Name | Data | Description |
| :--- | :--- | :--- |
| `onBeaconDetected` | `Beacon` | Emitted when a beacon (iBeacon or Eddystone) is detected. |
| `onBluetoothStateChange` | `{ state: BluetoothState }` | Emitted when Bluetooth is toggled. |
| `onScanStateChange` | `{ isScanning: boolean }` | Emitted when scanning starts or stops. |
| `onPermissionsChange` | `PermissionsResponse` | Emitted when permissions are granted or denied. |

### Types

#### `Beacon`
A union type of `IBeacon` or `Eddystone`.

#### `IBeacon`
```ts
{
  type: 'iBeacon';
  uuid: string;
  major: number;
  minor: number;
  rssi: number;
  address?: string;
  name?: string | null;
  txPower?: number;
  adHex?: string;
  battery?: number | null;
}
```

#### `Eddystone`
```ts
{
  type: 'eddystone';
  uuid: string;
  namespace: string;
  instance: string;
  rssi: number;
  txPower: number;
  address?: string;
  name: string | null;
  adHex: string;
}
```

#### `PermissionsResponse`
```ts
{
  granted: boolean;
  permissions: {
    location: PermissionInfo;
    bluetooth: PermissionInfo;
  };
}
```

#### `PermissionInfo`
```ts
{
  status: string;
  granted: boolean;
}
```


