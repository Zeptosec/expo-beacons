import Foundation
import CoreBluetooth
import CoreLocation

class BeaconManager: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    private var locationManager: CLLocationManager
    private var centralManager: CBCentralManager
    private var isScanning = false
    var onBeaconDetected: (([String: Any]) -> Void)?
    
    override init() {
        self.locationManager = CLLocationManager()
        self.centralManager = CBCentralManager()
        super.init()
        
        self.locationManager.delegate = self
        self.centralManager.delegate = self
    }
    
    func requestPermissions(completion: @escaping ([String: Bool]) -> Void) {
        locationManager.requestWhenInUseAuthorization()
        if centralManager.state == .unknown {
            centralManager.delegate = self // Trigger Bluetooth permission prompt
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let hasLocationPermission = self.locationManager.authorizationStatus == .authorizedWhenInUse || self.locationManager.authorizationStatus == .authorizedAlways
            let hasBluetoothPermission = self.centralManager.state == .poweredOn
            
            completion([
                "location": hasLocationPermission,
                "bluetooth": hasBluetoothPermission
            ])
        }
    }
    
    func startScanning() {
        guard !isScanning else { return }
        
        // Start iBeacon detection
        let beaconRegion = CLBeaconRegion(uuid: UUID(), identifier: "AnyBeacon")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
        
        // Start BLE scanning for Eddystone
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
        
        isScanning = true
    }
    
    func stopScanning() {
        guard isScanning else { return }
        
        // Stop iBeacon detection
        for region in locationManager.monitoredRegions {
            if let beaconRegion = region as? CLBeaconRegion {
                locationManager.stopMonitoring(for: beaconRegion)
                locationManager.stopRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
            }
        }
        
        // Stop BLE scanning
        centralManager.stopScan()
        isScanning = false
    }
    
    // MARK: - CLLocationManagerDelegate
    private func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], satisfying constraint: CLBeaconIdentityConstraint) {
        for beacon in beacons {
            let beaconData: [String: Any] = [
                "type": "iBeacon",
                "uuid": beacon.uuid.uuidString,
                "major": beacon.major,
                "minor": beacon.minor,
                "proximity": beacon.proximity.rawValue,
                "accuracy": beacon.accuracy,
                "rssi": beacon.rssi
            ]
            onBeaconDetected?(beaconData)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle Bluetooth state updates
        if central.state == .poweredOn {
            if isScanning {
                centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Parse Eddystone advertisement
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            for (uuid, data) in serviceData {
                if uuid.uuidString == "FEAA" { // Eddystone UUID
                    let eddystoneData = parseEddystoneData(data: data)
                    let beaconData: [String: Any] = [
                        "type": "Eddystone",
                        "namespaceId": eddystoneData.namespaceId,
                        "instanceId": eddystoneData.instanceId,
                        "rssi": RSSI
                    ]
                    onBeaconDetected?(beaconData)
                }
            }
        }
    }
    
    private func parseEddystoneData(data: Data) -> (namespaceId: String, instanceId: String) {
        let namespaceId = data.subdata(in: 2..<12).map { String(format: "%02X", $0) }.joined()
        let instanceId = data.subdata(in: 12..<18).map { String(format: "%02X", $0) }.joined()
        return (namespaceId, instanceId)
    }
}
