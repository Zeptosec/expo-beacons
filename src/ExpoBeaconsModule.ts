import { NativeModule, requireNativeModule } from 'expo';

import { BluetoothState, ExpoBeaconsModuleEvents, PermissionsResponse } from './ExpoBeacons.types';

declare class ExpoBeaconsModule extends NativeModule<ExpoBeaconsModuleEvents> {
  bluetoothState: BluetoothState;
  permissions: PermissionsResponse;
  isScanning: boolean;
  requestBluetoothEnable(): Promise<void>;
  requestPermissionsAsync(): Promise<PermissionsResponse>;
  startScan(): void;
  stopScan(): void;
  setRegions(uuids: string[]): void;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoBeaconsModule>('ExpoBeacons');
