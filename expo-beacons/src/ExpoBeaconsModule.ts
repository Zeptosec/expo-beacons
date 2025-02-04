import { NativeModule, requireNativeModule } from "expo";
import { PermissionResult } from ".";

// import { ExpoBeaconsModuleEvents } from './ExpoBeacons.types';

declare class ExpoBeaconsModule extends NativeModule<any> {
  getPermissions: () => Promise<PermissionResult>;
  requestPermissions: () => Promise<PermissionResult>;
  startScanning: (
    uuids: string[],
    eddystoneServiceUUID?: string,
  ) => Promise<void>;
  stopScanning: () => Promise<void>;
  updateMonitoredRegions: (uuids: string[]) => void;
  restartScanning: () => void;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoBeaconsModule>("ExpoBeacons");
