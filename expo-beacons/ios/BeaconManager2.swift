import CoreLocation
import CoreBluetooth

class BeaconManager2: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var onBeaconDetected: (([String: Any]) -> Void)?
    private var monitoredRegions: [CLBeaconIdentityConstraint] = []
    private var permissionCompletion: ((Bool) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            let status = locationManager.authorizationStatus
            
            if status == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
                self.permissionCompletion = { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                continuation.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
            }
        }
    }

    func startScanning(uuids: [String], onDetected: @escaping ([String: Any]) -> Void) {
        onBeaconDetected = onDetected
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            for uuid in uuids {
                let region = CLBeaconIdentityConstraint(uuid: UUID(uuidString: uuid)!)
                locationManager.startRangingBeacons(satisfying: region)
                monitoredRegions.append(region)
            }
            // Configure a generic beacon region to scan iBeacons
//            let region = CLBeaconRegion(uuid: UUID(uuidString: "16967031-4a76-9c35-886d-000050000035")!, identifier: "VOICE")
//            let region = CLBeaconIdentityConstraint(uuid: UUID(uuidString: "16967031-4a76-9c35-886d-000050000035")!)
//            let region2 = CLBeaconIdentityConstraint(uuid: UUID(uuidString: "16967031-4a76-9c35-886d-a0ba3b9eb045")!)
//            locationManager.startMonitoring(for: region)
//            locationManager.startRangingBeacons(satisfying: region)
//            locationManager.startRangingBeacons(satisfying: region2)

            // Start scanning for Eddystone beacons using CoreBluetooth
            // Eddystone detection requires a separate BLE manager
        }
    }
    
    func updateMonitoredRegions(with uuids: [String]) {
        let newUUIDs = Set(uuids.compactMap { UUID(uuidString: $0) })
        var existingUUIDs = Set(monitoredRegions.map { $0.uuid })
        
        // Remove regions that are no longer in the passed list
        for region in monitoredRegions where !newUUIDs.contains(region.uuid) {
            locationManager.stopRangingBeacons(satisfying: region)
            existingUUIDs.remove(region.uuid)
        }
        
        // Add new regions that are not already being monitored
        for uuid in newUUIDs.subtracting(existingUUIDs) {
            let region = CLBeaconIdentityConstraint(uuid: uuid)
            locationManager.startRangingBeacons(satisfying: region)
            monitoredRegions.append(region)
        }

        // Update monitored regions list after removals
        monitoredRegions = monitoredRegions.filter { newUUIDs.contains($0.uuid) }
    }

    func stopScanning() {
        for region in monitoredRegions {
            locationManager.stopRangingBeacons(satisfying: region)
        }
        monitoredRegions.removeAll()
//        locationManager.monitoredRegions.forEach { region in
//            if let beaconRegion = region as? CLBeaconRegion {
//                locationManager.stopMonitoring(for: beaconRegion)
//                locationManager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: beaconRegion.uuid))
//            }
//        }
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        for beacon in beacons {
//            dump(beacon)
            let beaconData: [String: Any] = [
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

//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        if status == .authorizedWhenInUse || status == .authorizedAlways {
//            // Permissions granted
//        } else {
//            // Handle denied permissions
//        }
//    }
}
