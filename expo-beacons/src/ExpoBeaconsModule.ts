import { NativeModule, requireNativeModule } from 'expo';

// import { ExpoBeaconsModuleEvents } from './ExpoBeacons.types';

declare class ExpoBeaconsModule extends NativeModule<any> {
  requestPermissions: () => Promise<boolean>;
  startScanning: (uuids: string[]) => Promise<void>;
  stopScanning: () => Promise<void>;
  updateMonitoredRegions: (uuids: string[]) => void;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoBeaconsModule>('ExpoBeacons');
