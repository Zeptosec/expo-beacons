package expo.modules.beacons

import android.content.Context
import android.util.Log
import org.altbeacon.beacon.*
import java.util.Observer

class BeaconScanner(context: Context) {

    private val beaconManager: BeaconManager = BeaconManager.getInstanceForApplication(context)

    init {
        beaconManager.beaconParsers.add(
            BeaconParser().setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24") // iBeacon
        )
        // Add beacon parsers for Eddystone
        beaconManager.beaconParsers.add(BeaconParser().setBeaconLayout(BeaconParser.EDDYSTONE_UID_LAYOUT))
    }

    fun startScan() {
        val region = Region("all-beacons", null, null, null)
        beaconManager.startRangingBeacons(region)

        beaconManager.addRangeNotifier { beacons, _ ->
            for (beacon in beacons) {
                if (beacon.serviceUuid == 0xFEAA) {
                    Log.d("expo.modules.beacons.BeaconScanner", "Eddystone detected: ${parseEddystone(beacon)}")
                } else {
                    Log.d("expo.modules.beacons.BeaconScanner", "iBeacon detected: ${parseIBeacon(beacon)}")
                }
            }
        }
    }

    fun stopScan() {
        beaconManager.stopRangingBeacons(Region("all-beacons", null, null, null))
    }

    private fun parseIBeacon(beacon: Beacon): Map<String, Any> {
        return mapOf(
            "rssi" to beacon.rssi,
            "uuid" to beacon.id1.toString(),
            "accuracy" to beacon.distance,
            "major" to beacon.id2.toInt(),
            "minor" to beacon.id3.toInt(),
            "proximity" to getProximity(beacon.distance)
        )
    }

    private fun parseEddystone(beacon: Beacon): Map<String, Any> {
        return mapOf(
            "rssi" to beacon.rssi,
            "uuid" to beacon.id1.toString(),
            "namespace" to beacon.id1.toString().substring(0, 20),
            "instance" to beacon.id1.toString().substring(20)
        )
    }

    private fun getProximity(distance: Double): Int {
        return when {
            distance < 0.5 -> 1  // Immediate
            distance < 2.0 -> 2  // Near
            else -> 3  // Far
        }
    }
}
