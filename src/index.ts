import { useEffect, useState } from 'react';
// Reexport the native module. On web, it will be resolved to ExpoBeaconsModule.web.ts
// and on native platforms to ExpoBeaconsModule.ts
import ExpoBeaconsModule from './ExpoBeaconsModule';
export { default } from './ExpoBeaconsModule';
export * from './ExpoBeacons.types';

export function useBluetoothState() {
  const [bluetoothState, setBluetoothState] = useState(ExpoBeaconsModule.bluetoothState);

  useEffect(() => {
    const subscription = ExpoBeaconsModule.addListener('onBluetoothStateChange', ({ state }) => {
      setBluetoothState(state);
    });

    return () => subscription.remove();
  }, []);

  return bluetoothState;
}

export function useIsScanning() {
  const [isScanning, setIsScanning] = useState(ExpoBeaconsModule.isScanning);

  useEffect(() => {
    const subscription = ExpoBeaconsModule.addListener('onScanStateChange', ({ isScanning }) => {
      setIsScanning(isScanning);
    });

    return () => subscription.remove();
  }, [])

  return isScanning;
}

export function usePermissions() {
  const [permissions, setPermissions] = useState(ExpoBeaconsModule.permissions);

  useEffect(() => {
    const subscription = ExpoBeaconsModule.addListener('onPermissionsChange', (data) => {
      setPermissions(data);
    });
    
    return () => subscription.remove();
  }, []);

  return { permissions, requestPermissions: ExpoBeaconsModule.requestPermissionsAsync };
}