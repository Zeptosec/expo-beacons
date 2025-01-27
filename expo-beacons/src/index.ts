// Reexport the native module. On web, it will be resolved to ExpoBeaconsModule.web.ts
// and on native platforms to ExpoBeaconsModule.ts
// export { default } from './ExpoBeaconsModule';

import ExpoBeaconsModule from "./ExpoBeaconsModule";

type IBeaconDataType = {
    "rssi": number;
    "uuid": string;
    "accuracy": number;  // iBeacon
    "major": number;     // iBeacon
    "minor": number;     // iBeacon
    "proximity": number; // iBeacon
};

type EddyStoneDataType = {
    "rssi": number;
    "uuid": string;
    namespace: string;   // EddyStone
    instance: string;     // EddyStone
};

export type DetectedBeacon = IBeaconDataType | EddyStoneDataType

export async function startScanning(uuids: string[]): Promise<void> {
    await ExpoBeaconsModule.startScanning(uuids);
}

export async function stopScanning(): Promise<void> {
    await ExpoBeaconsModule.stopScanning();
}

export async function requestPermissionsAsync(): Promise<boolean> {
    return await ExpoBeaconsModule.requestPermissions();
}

export function updateMonitoredRegions(uuids: string[]): void {
    ExpoBeaconsModule.updateMonitoredRegions(uuids);
}

export function addBeaconListener(
    listener: (event: { data: DetectedBeacon }) => void,
) {
    return ExpoBeaconsModule.addListener("onBeaconDetected", listener);
}

export function restartScanning(): void {
    ExpoBeaconsModule.restartScanning();
}