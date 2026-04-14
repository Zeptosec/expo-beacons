export type PermissionInfo = {
  status: string;
  granted: boolean;
  canAskAgain: boolean;
}

export type PermissionsResponse = {
  granted: boolean;
  permissions: Record<string, PermissionInfo>;
}

export type BluetoothState = 'on' | 'off' | 'unknown';

export type ExpoBeaconsModuleEvents = {
  onBeaconDetected: (data: Beacon) => void;
  onBluetoothStateChange: (data: { state: BluetoothState }) => void;
  onScanStateChange: (data: { isScanning: boolean }) => void;
  onPermissionsChange: (data: PermissionsResponse) => void;
};

export type IBeacon = {
  type: 'iBeacon';
  uuid: string;
  address?: string;
  name?: string | null;
  major: number;
  minor: number;
  rssi: number;
  txPower?: number;
  adHex?: string; // The raw advertisement data in hexadecimal format. Each byte is separated by space.
  battery?: number | null; // Battery level if available, otherwise null.
}

export type Eddystone = {
  type: 'eddystone';
  address?: string;
  uuid: string;
  name: string | null;
  namespace: string;
  instance: string;
  rssi: number;
  txPower: number;
  adHex: string; // The raw advertisement data in hexadecimal format. Each byte is separated by space.
}

export type Beacon = IBeacon | Eddystone;