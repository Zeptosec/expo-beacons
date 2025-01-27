// Main Swift file for Expo module to detect iBeacon and Eddystone beacons
import ExpoModulesCore

// Exported Expo module
public class ExpoBeaconsModule: Module {
    public func definition() -> ModuleDefinition {
        Name("ExpoBeacons")
        
        AsyncFunction("startScanning", startScanning)
        AsyncFunction("stopScanning", stopScanning)
        Function("updateMonitoredRegions", updateMonitoredRegions)
        AsyncFunction("requestPermissions", requestPermissions)
        Function("restartScanning", restartScanning)
        
        Events("onBeaconDetected")
    }
    
    private let beaconManager = BeaconManager()
    private let eddystoneManager = EddystoneManager()
    
    func updateMonitoredRegions(with uuids: [String]) throws {
        beaconManager.updateMonitoredRegions(with: uuids)
    }
    
    func startScanning(uuids: [String], eddystoneServiceUUID: String? = nil) async throws {
        beaconManager.startScanning(uuids: uuids) { beaconData in
            self.sendEvent("onBeaconDetected", ["data": beaconData])
        }
        eddystoneManager.startScanning(eddystoneServiceUUID: eddystoneServiceUUID) { beaconData in
            self.sendEvent("onBeaconDetected", ["data": beaconData])
        }
    }
    
    func stopScanning() async throws {
        beaconManager.stopScanning()
        eddystoneManager.stopScanning()
    }
    
    func requestPermissions() async throws -> Bool {
        let isBluetoothGranted = await eddystoneManager.requestPermissions()
        let isBeaconGranted = await beaconManager.requestPermissions()
        
        return isBeaconGranted && isBluetoothGranted;
    }
    
    func restartScanning() {
        eddystoneManager.restartScanning()
    }
}
