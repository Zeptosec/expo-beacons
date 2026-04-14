import CoreLocation
import CoreBluetooth
import ExpoModulesCore

public enum PermissionStatus: String {
    case unknown = "unknown"
    case notDetermined = "notDetermined"
    case denied = "denied"
    case restricted = "restricted"
    case authorizedAlways = "authorizedAlways"
    case authorizedWhenInUse = "authorizedWhenInUse"
    case limited = "limited"
    case allowedAlways = "allowedAlways"
    
    var isGranted: Bool {
        return self == .authorizedAlways || self == .authorizedWhenInUse || self == .allowedAlways
    }
}

class PermissionManager: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    private let locationManager = CLLocationManager()
    private var centralManager: CBCentralManager?
    
    var onPermissionsChange: (() -> Void)?
    private var onPermissionsResolved: (() -> Void)?
    
    var bluetoothState: CBManagerState {
        centralManager?.state ?? .unknown
    }
    
    var isBluetoothEnabled: Bool {
        bluetoothState == .poweredOn
    }
    
    var locationStatus: PermissionStatus {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedAlways: return .authorizedAlways
        case .authorizedWhenInUse: return .authorizedWhenInUse
        case .authorized: return .authorizedAlways
        @unknown default: return .unknown
        }
    }
    
    var bluetoothStatus: PermissionStatus {
        let status = CBCentralManager.authorization
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .allowedAlways: return .allowedAlways
        @unknown default: return .unknown
        }
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        if bluetoothStatus == .notDetermined {
            centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        }
    }
    
    func requestPermissions(onResolved: @escaping () -> Void) {
        self.onPermissionsResolved = onResolved
        
        if (locationStatus.isGranted && bluetoothStatus.isGranted) {
            onResolved()
            return
        }

        if locationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        if bluetoothStatus == .notDetermined {
            // Trigger Bluetooth permission prompt by initializing CBCentralManager
            centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        }
    }
    
    private func checkAndResolve() {
        guard let resolve = onPermissionsResolved else { return }
        
        if locationStatus != .notDetermined && bluetoothStatus != .notDetermined {
            resolve()
            onPermissionsResolved = nil
        }
    }
    
    func getPermissionsResponse() -> [String: Any] {
        let isLocGranted = locationStatus.isGranted
        let isBtGranted = bluetoothStatus.isGranted
        
        // On iOS, scanning for beacons depends PRIMARILY on Location permission.
        return [
            "granted": isLocGranted,
            "permissions": [
                "location": ["granted": isLocGranted, "status": locationStatus.rawValue],
                "bluetooth": ["granted": isBtGranted, "status": bluetoothStatus.rawValue]
            ]
        ]
    }
    
    func mapBluetoothState(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOn:
            return "on"
        case .poweredOff:
            return "off"
        case .resetting:
            return "off"
        case .unauthorized:
            return "off"
        case .unsupported:
            return "off"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onPermissionsChange?()
        checkAndResolve()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        onPermissionsChange?()
        checkAndResolve()
    }
}

