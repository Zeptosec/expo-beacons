import CoreLocation
import CoreBluetooth

class BeaconManager: NSObject, CLLocationManagerDelegate {
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
                "rssi": beacon.rssi,
            ]
            onBeaconDetected?(beaconData)
        }
    }
}
