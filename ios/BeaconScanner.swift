import CoreLocation
import CoreBluetooth
import ExpoModulesCore

class BeaconScanner: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    private var locationManager: CLLocationManager?
    private var centralManager: CBCentralManager?
    private var onScanStateChanged: (Bool) -> Void
    private var onResult: (([String: Any?]) -> Void)?
    private var beaconRegions: [CLBeaconRegion] = []
    
    var isScanning = false {
        didSet {
            onScanStateChanged(isScanning)
        }
    }
    
    init(onScanStateChanged: @escaping (Bool) -> Void) {
        self.onScanStateChanged = onScanStateChanged
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    }
    
    func setRegions(_ uuids: [String]) {
        // Stop current scanning if active before updating regions
        let wasScanning = isScanning
        if wasScanning {
            stopScanning()
        }
        
        self.beaconRegions = uuids.compactMap { uuidString -> CLBeaconRegion? in
            guard let uuid = UUID(uuidString: uuidString) else {
                print("Invalid UUID: \(uuidString)")
                return nil
            }
            // Use the UUID string itself as the identifier when not provided
            if #available(iOS 13.0, *) {
                return CLBeaconRegion(uuid: uuid, identifier: uuidString)
            } else {
                return CLBeaconRegion(proximityUUID: uuid, identifier: uuidString)
            }
        }
        
        // Restart scanning if it was active
        if wasScanning {
            if let resultHandler = self.onResult {
                startScanning(onResult: resultHandler)
            }
        }
    }
    
    func startScanning(onResult: @escaping ([String: Any]) -> Void) {
        if isScanning { return }
        self.onResult = onResult
        
        // 1. Start iBeacon scanning via CoreLocation
        for region in beaconRegions {
            if #available(iOS 13.0, *) {
                locationManager?.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
            } else {
                locationManager?.startRangingBeacons(in: region)
            }
        }
        
        // 2. Start Eddystone scanning via CoreBluetooth
        if centralManager?.state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: [BeaconParser.eddystoneServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
        
        isScanning = true
    }
    
    func stopScanning() {
        guard isScanning else { return }
        
        // 1. Stop iBeacon scanning
        for region in beaconRegions {
            if #available(iOS 13.0, *) {
                locationManager?.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
            } else {
                locationManager?.stopRangingBeacons(in: region)
            }
        }
        
        // 2. Stop Eddystone scanning
        centralManager?.stopScan()
        
        isScanning = false
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        for beacon in beacons {
            var beaconUUID: String
            if #available(iOS 13.0, *) {
                beaconUUID = beacon.uuid.uuidString
            } else {
                beaconUUID = beacon.proximityUUID.uuidString
            }
            
            let ibeacon = IBeacon(
                uuid: beaconUUID,
                major: beacon.major.intValue,
                minor: beacon.minor.intValue,
                rssi: beacon.rssi,
                adHex: nil
            )
            
            onResult?(ibeacon.toMap())
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if isScanning && central.state == .poweredOn {
            central.scanForPeripherals(withServices: [BeaconParser.eddystoneServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        if let beacon = BeaconParser.parseFromAdvertisement(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi) {
            onResult?(beacon.toMap())
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region: \(region?.identifier ?? "unknown"), error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
}

