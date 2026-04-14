import Foundation
import CoreBluetooth

class BeaconParser {
    static let eddystoneServiceUUID = CBUUID(string: "FEAA")

    static func parseFromAdvertisement(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) -> Beacon? {
        let name = peripheral.name
        let rssiVal = rssi.intValue

        // Hex representation of all advertisement data for debugging/parity
        var adHex = ""
        // For Eddystone, we want the data associated with FEAA (Eddystone Service UUID)
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
           let eddystoneData = serviceData[eddystoneServiceUUID] {
            adHex = eddystoneData.map { String(format: "%02x", $0) }.joined(separator: " ")
        }
        
        // 2. Try Eddystone (Service Data 0xFEAA)
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
           let eddystoneData = serviceData[eddystoneServiceUUID] {
            
            if eddystoneData.count >= 1 {
                let frameType = eddystoneData[0]
                
                // Eddystone-UID (0x00)
                if frameType == 0x00 && eddystoneData.count >= 18 {
                    let txPower = Int(Int8(bitPattern: eddystoneData[1]))
                    let namespace = eddystoneData.subdata(in: 2..<12).map { String(format: "%02x", $0) }.joined()
                    let instance = eddystoneData.subdata(in: 12..<18).map { String(format: "%02x", $0) }.joined()
                    let uuid = bytesToUuid(eddystoneData.subdata(in: 2..<18))

                    return Eddystone(
                        uuid: uuid,
                        name: name,
                        namespace: namespace,
                        instance: instance,
                        rssi: rssiVal,
                        txPower: txPower,
                        adHex: adHex
                    )
                }
            }
        }

        return nil
    }

    private static func bytesToUuid(_ data: Data) -> String {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        if hex.count != 32 { return hex }
        
        let indices = [8, 13, 18, 23]
        var result = hex
        for (offset, index) in indices.enumerated() {
            let insertPos = result.index(result.startIndex, offsetBy: index + offset)
            result.insert("-", at: insertPos)
        }
        return result
    }
}
