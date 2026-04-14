import Foundation

struct IBeacon: Beacon {
    let type: String = "iBeacon"
    let uuid: String
    let major: Int
    let minor: Int
    let rssi: Int

    func toMap() -> [String: Any?] {
        return [
            "type": type,
            "uuid": uuid,
            "major": major,
            "minor": minor,
            "rssi": rssi,
        ]
    }
}
