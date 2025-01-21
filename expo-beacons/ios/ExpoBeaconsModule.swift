// Main Swift file for Expo module to detect iBeacon and Eddystone beacons
import CoreLocation
import CoreBluetooth
import ExpoModulesCore

// Exported Expo module
public class ExpoBeaconsModule: Module {
    public func definition() -> ModuleDefinition {
        Name("ExpoBeacons")

        AsyncFunction("startScanning", startScanning)
        AsyncFunction("stopScanning", stopScanning)
        Function("updateMonitoredRegions", updateMonitoredRegions)
        AsyncFunction("requestPermissions", requestPermissions)

        Events("onBeaconDetected")
    }

    private let beaconManager = BeaconManager2()

    func updateMonitoredRegions(with uuids: [String]) throws {
        beaconManager.updateMonitoredRegions(with: uuids)
    }
    
    func startScanning(uuids: [String]) async throws {
        beaconManager.startScanning(uuids: uuids) { beaconData in
            self.sendEvent("onBeaconDetected", ["data": beaconData])
        }
    }

    func stopScanning() async throws {
        beaconManager.stopScanning()
    }

    func requestPermissions() async throws -> Bool {
        return await beaconManager.requestPermissions()
    }
}


//import ExpoModulesCore
//
//public class ExpoBeaconsModule: Module {
//    
//    // Each module class must implement the definition function. The definition consists of components
//    // that describes the module's functionality and behavior.
//    // See https://docs.expo.dev/modules/module-api for more details about available components.
//    
//    private var beaconManager: BeaconManager?
//    
//    public func definition() -> ModuleDefinition {
//        // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
//        // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
//        // The module will be accessible from `requireNativeModule('ExpoBeacons')` in JavaScript.
//        Name("ExpoBeacons")
//        
//        // Start scanning for beacons
//        AsyncFunction("requestPermissionsAsync") { () -> [String: Bool] in
//            return try await self.requestPermissions()
//        }
//        
//        AsyncFunction("startScanning") {
//            self.startScanning()
//        }
//        
//        AsyncFunction("stopScanning") {
//            self.stopScanning()
//        }
//        
//        Events("onBeaconDetected")
//        
//        OnCreate {
//            self.beaconManager = BeaconManager()
//            self.beaconManager?.onBeaconDetected = { [weak self] beaconData in
//                self?.sendEvent("onBeaconDetected", beaconData)
//            }
//        }
//    }
//    
//    private func requestPermissions() async throws -> [String: Bool] {
//        guard let beaconManager = beaconManager else { return [:] }
//        
//        return try await withCheckedThrowingContinuation { continuation in
//            beaconManager.requestPermissions { result in
//                continuation.resume(returning: result)
//            }
//        }
//    }
//    
//    private func startScanning() {
//        beaconManager?.startScanning()
//    }
//    
//    private func stopScanning() {
//        beaconManager?.stopScanning()
//    }
//}
