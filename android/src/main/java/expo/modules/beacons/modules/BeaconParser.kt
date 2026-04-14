package expo.modules.beacons.modules

import android.bluetooth.le.ScanResult
import android.os.ParcelUuid
import kotlin.collections.isNotEmpty
import kotlin.collections.sliceArray

class BeaconParser {
    companion object {
        private val EDDYSTONE_SERVICE_UUID = ParcelUuid.fromString("0000feaa-0000-1000-8000-00805f9b34fb")

        fun parseFromScanResult(result: ScanResult): Beacon? {
            val scanRecord = result.scanRecord ?: return null
            val bytes = scanRecord.bytes ?: return null
            val adHex = bytes.joinToString(" "){ "%02x".format(it.toInt() and 0xff) }
            val address = result.device.address
            val rssi = result.rssi
            val name = result.scanRecord?.deviceName

            // Try iBeacon (Apple Manufacturer Data 0x004C)
            val appleData = scanRecord.getManufacturerSpecificData(0x004c)
            if (appleData != null && appleData.size >= 23 && appleData[0] == 0x02.toByte() && appleData[1] == 0x15.toByte()) {
                val uuid = bytesToUuid(appleData.sliceArray(2..17))
                val major = ((appleData[18].toInt() and 0xff) shl 8) or (appleData[19].toInt() and 0xff)
                val minor = ((appleData[20].toInt() and 0xff) shl 8) or (appleData[21].toInt() and 0xff)
                val txPower = appleData[22].toInt()
                var battery: Int? = null

                if (bytes.size >= 42) {
                    // Check if there are any non-zero bytes starting from index 29 
                    // to verify if this is an extended advertisement with actual data
                    val zeroByte = 0.toByte()
                    val hasData = (29 until bytes.size).any { bytes[it] != zeroByte }
                    if (hasData) {
                        val batteryStatus = bytes[41].toInt() and 0xff
                        // could get false positives so verify that battery status is in range at least
                        if (batteryStatus in 1..100) {
                            battery = batteryStatus
                        }
                    }
                }

                return IBeacon(
                    name = name,
                    address = address,
                    rssi = rssi,
                    adHex = adHex,
                    uuid = uuid,
                    major = major,
                    minor = minor,
                    txPower = txPower,
                    battery = battery,
                )
            }

            // Try Eddystone (Service Data 0xFEAA)
            val eddystoneData = scanRecord.getServiceData(EDDYSTONE_SERVICE_UUID)
            if (eddystoneData != null && eddystoneData.isNotEmpty()) {
                val frameType = eddystoneData[0].toInt() and 0xff

                // Eddystone-UID (0x00) is 20 bytes: [FrameType(1), TXPower(1), Namespace(10), Instance(6), Reserved(2)]
                if (frameType == 0x00 && eddystoneData.size >= 18) {
                    val txPower = eddystoneData[1].toInt()
                    val uuid = bytesToUuid(eddystoneData.sliceArray(2..17))
                    val namespace = eddystoneData.sliceArray(2..11).joinToString("") { "%02x".format(it.toInt() and 0xff) }
                    val instance = eddystoneData.sliceArray(12..17).joinToString("") { "%02x".format(it.toInt() and 0xff) }

                    return EddyStone(
                        name = name,
                        address = address,
                        rssi = rssi,
                        txPower = txPower,
                        adHex = adHex,
                        uuid = uuid,
                        namespace = namespace,
                        instance = instance
                    )
                }

                // I need to return full data, so if the Eddystone is sending data in frames,
                // then maybe I need to cache previously received data and merge it together
                // TLM (0x20) contains battery voltage
//                if (frameType == 0x20 && eddystoneData.size >= 4) {
//                    val battery = ((eddystoneData[2].toInt() and 0xff) shl 8) or (eddystoneData[3].toInt() and 0xff)
//                    return expo.modules.beacons.Beacon(
//                        type = "Eddystone",
//                        name = name,
//                        address = address,
//                        rssi = rssi,
//                        advertisement = adHexList,
//                        frameType = frameType,
//                        battery = battery
//                    )
//                }

//                return Beacon(
//                    type = "Eddystone",
//                    name = name,
//                    address = address,
//                    rssi = rssi,
//                    advertisement = adHexList,
//                    frameType = frameType
//                )
            }

            return null
        }

        private fun bytesToUuid(bytes: ByteArray): String {
            val sb = StringBuilder()
            for (i in bytes.indices) {
                sb.append("%02x".format(bytes[i].toInt() and 0xff))
                if (i == 3 || i == 5 || i == 7 || i == 9) sb.append("-")
            }
            return sb.toString()
        }
    }
}