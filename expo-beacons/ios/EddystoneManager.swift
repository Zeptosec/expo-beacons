import CoreBluetooth

class EddystoneManager: NSObject, CBCentralManagerDelegate {
    private let defaultServiceUUID = "FEAA"
    private var centralManager: CBCentralManager!
    private var onEddystoneDetected: (([String: Any]) -> Void)?
    private var permissionCompletion: ((Bool) -> Void)?
    private var serviceUUID: String
    
    override init() {
        serviceUUID = defaultServiceUUID
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func requestPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            if centralManager.state == .unknown || centralManager.state == .resetting {
                self.permissionCompletion = { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                continuation.resume(returning: centralManager.state == .poweredOn)
            }
        }
    }
    
    func startScanning(eddystoneServiceUUID: String? = nil, onDetected: @escaping ([String: Any]) -> Void) {
        print("Start eddystone scan")
        print("Bluetooth state: \(centralManager.state)")
        
        serviceUUID = eddystoneServiceUUID ?? defaultServiceUUID
        onEddystoneDetected = onDetected
        
        if centralManager.state == .poweredOn {
            restartScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func restartScanning() {
        centralManager.stopScan()
        let eddystoneServiceUUID = CBUUID(string: serviceUUID)
        centralManager.scanForPeripherals(withServices: [eddystoneServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        print("Restarting Eddystone scanning...")
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            permissionCompletion?(true)
        case .unauthorized, .poweredOff, .unsupported:
            permissionCompletion?(false)
        default:
            break
        }
    }
    
    // Called when a beacon is found
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] else {
            return
        }
        
        if let eddystoneData = serviceData[CBUUID(string: serviceUUID)] {
            parseEddystoneData(eddystoneData, rssi: RSSI)
        }
    }
    
    // Handles the Eddystone data
    private func parseEddystoneData(_ data: Data, rssi: NSNumber) {
        guard data.count > 1 else { return }
        let frameType = data[0]
                
        switch frameType {
        case 0x00:  // UID frame
            let namespace = data.subdata(in: 2..<12).map { String(format: "%02x", $0) }.joined()
            let instance = data.subdata(in: 12..<18).map { String(format: "%02x", $0) }.joined()
            print("Eddystone UID detected: Namespace=\(namespace), Instance=\(instance), RSSI=\(rssi)")
            
            let beaconData: [String: Any] = [
                "uuid": namespace + instance,
                "namespace": namespace,
                "instance": instance,
                "rssi": rssi,
            ]
            onEddystoneDetected?(beaconData)
            
        case 0x10:  // URL frame
            let urlScheme = data[2]
            let encodedURL = data.subdata(in: 3..<data.count)
            if let decodedURL = decodeEddystoneURL(urlScheme: urlScheme, data: encodedURL) {
                print("Eddystone URL detected: \(decodedURL), RSSI=\(rssi)")
            }
            
        case 0x20:  // TLM frame (Telemetry data)
            print("Eddystone TLM detected: Battery Voltage and Temperature")
            
        default:
            print("Unknown Eddystone frame detected")
        }
    }
    
    // Decodes an Eddystone URL frame
    private func decodeEddystoneURL(urlScheme: UInt8, data: Data) -> String? {
        let urlSchemes = ["http://www.", "https://www.", "http://", "https://"]
        let encodedChars: [UInt8: String] = [
            0x00: ".com/", 0x01: ".org/", 0x02: ".edu/", 0x03: ".net/",
            0x04: ".info/", 0x05: ".biz/", 0x06: ".gov/", 0x07: ".com",
            0x08: ".org", 0x09: ".edu", 0x0A: ".net", 0x0B: ".info"
        ]
        
        guard Int(urlScheme) < urlSchemes.count else { return nil }
        var url = urlSchemes[Int(urlScheme)]
        for byte in data {
            if let encoded = encodedChars[byte] {
                url += encoded
            } else {
                url += String(format: "%c", byte)
            }
        }
        return url
    }
}
