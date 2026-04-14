import Foundation

struct Eddystone: Beacon {
    let type: String = "eddystone"
    let uuid: String
    let name: String?
    let namespace: String
    let instance: String
    let rssi: Int
    let txPower: Int
    let adHex: String

    func toMap() -> [String: Any?] {
        return [
            "type": type,
            "uuid": uuid,
            "name": name,
            "namespace": namespace,
            "instance": instance,
            "rssi": rssi,
            "txPower": txPower,
            "adHex": adHex
        ]
    }
}
