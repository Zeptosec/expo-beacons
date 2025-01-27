import CoreBluetooth

class BluetoothPermissionManager: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager!
    private var continuation: CheckedContinuation<Bool, Never>?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Async function to request Bluetooth permissions
    func requestBluetoothPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            continuation?.resume(returning: true)
            print("Bluetooth is ON")
        case .unauthorized, .poweredOff, .unsupported:
            continuation?.resume(returning: false)
            print("Bluetooth is not available or permission denied")
        default:
            continuation?.resume(returning: false)
            print("Unknown Bluetooth state")
        }
        continuation = nil
    }
}
