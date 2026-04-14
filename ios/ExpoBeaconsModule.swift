import ExpoModulesCore
import CoreBluetooth
import CoreLocation

public class ExpoBeaconsModule: Module {
    private var beaconScanner: BeaconScanner?
    private var centralManager: CBCentralManager?
    private let permissionManager = PermissionManager()
    
    public func definition() -> ModuleDefinition {
        Name("ExpoBeacons")
        
        Events("onBluetoothStateChange", "onBeaconDetected", "onScanStateChange", "onPermissionsChange")
        
        OnCreate {
            self.permissionManager.onPermissionsChange = { [weak self] in
                guard let self = self else { return }
                
                // Keep permissions event in sync
                self.sendEvent("onPermissionsChange", self.permissionManager.getPermissionsResponse())
                
                // Handle Bluetooth state changes for scanning
                let stateString = self.permissionManager.mapBluetoothState(self.permissionManager.bluetoothState)
                self.sendEvent("onBluetoothStateChange", [
                    "state": stateString
                ])
                
                // If Bluetooth is turned off, stop scanning
                if !self.permissionManager.isBluetoothEnabled {
                    self.beaconScanner?.stopScanning()
                }
            }
            
            self.beaconScanner = BeaconScanner { [weak self] isScanning in
                self?.sendEvent("onScanStateChange", [
                    "isScanning": isScanning
                ])
            }
            
            // We need a CBCentralManager to pass to the scanner
            self.centralManager = CBCentralManager(delegate: nil, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        }
        
        Property("bluetoothState") {
            return self.permissionManager.mapBluetoothState(self.permissionManager.bluetoothState)
        }
        
        Property("permissions") {
            return self.permissionManager.getPermissionsResponse()
        }
        
        Property("locationStatus") {
            return self.permissionManager.locationStatus.rawValue
        }
        
        Property("bluetoothStatus") {
            return self.permissionManager.bluetoothStatus.rawValue
        }
        
        Property("isScanning") {
            return self.beaconScanner?.isScanning ?? false
        }
        
        Function("startScan") {
            self.beaconScanner?.startScanning { [weak self] beaconMap in
                self?.sendEvent("onBeaconDetected", beaconMap)
            }
        }
        
        Function("stopScan") {
            self.beaconScanner?.stopScanning()
        }
        
        Function("setRegions") { (regions: [String]) in
            self.beaconScanner?.setRegions(regions)
        }
        
        AsyncFunction("requestPermissionsAsync") { (promise: Promise) in
            self.permissionManager.requestPermissions { [weak self] in
                guard let self = self else { return }
                promise.resolve(self.permissionManager.getPermissionsResponse())
            }
        }
        
        AsyncFunction("requestBluetoothEnable") {
            // iOS does not allow apps to programmatically turn on Bluetooth.
            // The best we can do is show the system alert if CBCentralManagerOptionShowPowerAlertKey was true,
            // which we set to false to match the custom behavior.
            print("requestBluetoothEnable is not supported on iOS")
        }
    }
}

internal class BluetoothDisabledException: Exception, @unchecked Sendable {
    override var reason: String {
        "Bluetooth is not enabled"
    }
}

internal class ScannerNotAvailableException: Exception, @unchecked Sendable {
    override var reason: String {
        "Bluetooth LE Scanner is not available"
    }
}

internal class PermissionsModuleNotFoundException: Exception, @unchecked Sendable {
    override var reason: String {
        "Permissions module not found"
    }
}


