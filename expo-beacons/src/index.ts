// Reexport the native module. On web, it will be resolved to ExpoBeaconsModule.web.ts
// and on native platforms to ExpoBeaconsModule.ts
// export { default } from './ExpoBeaconsModule';

import ExpoBeaconsModule from "./ExpoBeaconsModule";

export type PermissionResult = {
    canAskAgain: boolean,
    expires: string,
    granted: boolean,
    status: 'granted' | 'undetermined'
}

type IBeaconDataType = {
    "rssi": number;
    "uuid": string;
    "accuracy": number;
    "major": number;
    "minor": number;
    "proximity": number;
};

type EddyStoneDataType = {
    "rssi": number;
    "uuid": string;
    namespace: string;
    instance: string;
};

export type DetectedBeacon = IBeaconDataType | EddyStoneDataType

export async function startScanning(uuids: string[]): Promise<void> {
    await ExpoBeaconsModule.startScanning(uuids);
}

export async function stopScanning(): Promise<void> {
    await ExpoBeaconsModule.stopScanning();
}

/**
 * Get the required permissions for iBeacon and Eddystone scanning.
 * @returns 
 */
export async function requestPermissionsAsync(): Promise<PermissionResult> {
    // check if already have the required permissions
    const perms = await ExpoBeaconsModule.getPermissions();
    if (!perms.granted && perms.canAskAgain) {
        // request the required permissions
        const request = await ExpoBeaconsModule.requestPermissions();
        if (!request.granted) {
            return request;
        }
        return request;
    }
    return perms;
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